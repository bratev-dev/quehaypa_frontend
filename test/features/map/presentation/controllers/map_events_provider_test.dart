import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/controllers/map_events_provider.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/presentation/controllers/location_controller.dart';
import 'package:frontend/features/location/presentation/controllers/location_state.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/domain/usecases/get_events_use_case.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';

class _EventsRepository implements PreferencesRepository {
  _EventsRepository(this.events);

  final List<EventSeed> events;
  String? requestedCategory;
  ({double latitude, double longitude, int radiusKm})? nearbyRequest;

  @override
  Future<List<EventSeed>> getEvents({String? category}) async {
    requestedCategory = category;
    return events;
  }

  @override
  Future<List<EventSeed>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) async {
    nearbyRequest = (
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return events;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestLocationController extends LocationController {
  void setDevice() {
    state = const LocationState(
      status: LocationStatus.ready,
      location: UserLocation(
        latitude: 2.44,
        longitude: -76.61,
        source: LocationSource.device,
      ),
    );
  }
}

class _DelayedEventsRepository implements PreferencesRepository {
  final general = Completer<List<EventSeed>>();
  final nearby = Completer<List<EventSeed>>();

  @override
  Future<List<EventSeed>> getEvents({String? category}) => general.future;

  @override
  Future<List<EventSeed>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) => nearby.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('la vista de prueba ubica tres eventos en curso o próximos', () {
    final now = DateTime(2026, 11, 18, 10);
    final events = previewMapEvents(now);

    expect(events, hasLength(3));
    expect(events.map((event) => event.id), [-1, -2, -3]);
    expect(events.every((event) => event.latitude != null), isTrue);
    expect(events.every((event) => event.longitude != null), isTrue);
    expect(DateTime.parse(events.first.startsAt!).isBefore(now), isTrue);
    expect(DateTime.parse(events.first.endsAt!).isAfter(now), isTrue);
    expect(DateTime.parse(events.last.startsAt!).isAfter(now), isTrue);
  });

  test('el proveedor pide todos los eventos y omite los terminados', () async {
    final now = DateTime.now();
    final repository = _EventsRepository([
      EventSeed(
        id: 1,
        title: 'En curso',
        category: 'Música',
        eventText: '',
        startsAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        endsAt: now.add(const Duration(hours: 1)).toIso8601String(),
      ),
      EventSeed(
        id: 2,
        title: 'Terminado',
        category: 'Arte',
        eventText: '',
        startsAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        endsAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        getEventsUseCaseProvider.overrideWithValue(GetEvents(repository)),
      ],
    );
    addTearDown(container.dispose);

    final events = await container.read(mapEventsProvider.future);

    expect(repository.requestedCategory, isNull);
    expect(events.map((event) => event.id), [1]);
  });

  test('el punto manual usa cinco kilómetros iniciales', () async {
    final repository = _EventsRepository([]);
    final container = ProviderContainer(
      overrides: [
        getEventsUseCaseProvider.overrideWithValue(GetEvents(repository)),
        mapSearchOptionsProvider.overrideWith(
          (ref) => (manual: const EventCoordinates(4.6, -74.08), radiusKm: 5),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(mapEventsProvider.future);

    expect(repository.nearbyRequest, (
      latitude: 4.6,
      longitude: -74.08,
      radiusKm: 5,
    ));
  });

  test('GPS usa el radio elegido y el punto manual tiene prioridad', () async {
    final repository = _EventsRepository([]);
    final location = _TestLocationController();
    final container = ProviderContainer(
      overrides: [
        getEventsUseCaseProvider.overrideWithValue(GetEvents(repository)),
        locationControllerProvider.overrideWith(() => location),
      ],
    );
    addTearDown(container.dispose);
    container.read(locationControllerProvider);
    location.setDevice();
    container.read(mapSearchOptionsProvider.notifier).state = (
      manual: null,
      radiusKm: 10,
    );

    await container.read(mapEventsProvider.future);
    expect(repository.nearbyRequest, (
      latitude: 2.44,
      longitude: -76.61,
      radiusKm: 10,
    ));

    container.read(mapSearchOptionsProvider.notifier).state = (
      manual: const EventCoordinates(4.6, -74.08),
      radiusKm: 10,
    );
    await container.read(mapEventsProvider.future);
    expect(repository.nearbyRequest, (
      latitude: 4.6,
      longitude: -74.08,
      radiusKm: 10,
    ));
  });

  test(
    'una respuesta anterior no reemplaza los pines del radio nuevo',
    () async {
      final repository = _DelayedEventsRepository();
      final container = ProviderContainer(
        overrides: [
          getEventsUseCaseProvider.overrideWithValue(GetEvents(repository)),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(mapEventsProvider, (_, _) {});
      addTearDown(subscription.close);
      container.read(mapSearchOptionsProvider.notifier).state = (
        manual: const EventCoordinates(4.6, -74.08),
        radiusKm: 5,
      );
      EventSeed event(int id) => EventSeed(
        id: id,
        title: 'Evento $id',
        category: 'Arte',
        eventText: '',
        startsAt: DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      );

      repository.nearby.complete([event(2)]);
      await container.read(mapEventsProvider.future);
      repository.general.complete([event(1)]);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(mapEventsProvider).requireValue.single.id, 2);
    },
  );
}
