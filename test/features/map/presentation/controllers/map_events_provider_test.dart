import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/controllers/map_events_provider.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/domain/usecases/get_events_use_case.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';

class _EventsRepository implements PreferencesRepository {
  _EventsRepository(this.events);

  final List<EventSeed> events;
  String? requestedCategory;

  @override
  Future<List<EventSeed>> getEvents({String? category}) async {
    requestedCategory = category;
    return events;
  }

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
}
