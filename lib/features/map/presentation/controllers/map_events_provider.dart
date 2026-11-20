import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../location/domain/entities/user_location.dart';
import '../../../location/presentation/controllers/location_controller.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../domain/entities/event_coordinates.dart';
import '../../domain/usecases/current_and_upcoming_map_events.dart';

const _previewEnabled = bool.fromEnvironment('MAP_EVENTS_PREVIEW');

typedef MapSearchOptions = ({EventCoordinates? manual, int radiusKm});

final mapSearchOptionsProvider = StateProvider.autoDispose<MapSearchOptions>(
  (ref) => (manual: null, radiusKm: 5),
);

List<EventSeed> previewMapEvents(DateTime now) => [
  EventSeed(
    id: -1,
    title: 'Música en el centro',
    category: 'Música',
    eventText: 'En curso',
    venue: 'Parque Caldas',
    latitude: 2.4419,
    longitude: -76.6063,
    startsAt: now.subtract(const Duration(minutes: 30)).toIso8601String(),
    endsAt: now.add(const Duration(hours: 2)).toIso8601String(),
    isPaid: false,
  ),
  EventSeed(
    id: -2,
    title: 'Arte en Popayán',
    category: 'Arte',
    eventText: 'En curso',
    venue: 'Centro histórico',
    latitude: 2.4448,
    longitude: -76.6147,
    startsAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
    endsAt: now.add(const Duration(hours: 1)).toIso8601String(),
    isPaid: true,
  ),
  EventSeed(
    id: -3,
    title: 'Cine al aire libre',
    category: 'Cultura',
    eventText: 'Próximamente',
    venue: 'Parque Benito Juárez',
    latitude: 2.4470,
    longitude: -76.6010,
    startsAt: now.add(const Duration(hours: 2)).toIso8601String(),
    endsAt: now.add(const Duration(hours: 4)).toIso8601String(),
    isPaid: false,
  ),
];

final mapEventsProvider = FutureProvider.autoDispose<List<EventSeed>>((ref) {
  final now = DateTime.now();
  final options = ref.watch(mapSearchOptionsProvider);
  final device = options.manual == null
      ? ref.watch(locationControllerProvider.select((state) => state.location))
      : null;
  final reference = options.manual;
  final latitude =
      reference?.latitude ??
      (device?.source == LocationSource.device ? device!.latitude : null);
  final longitude =
      reference?.longitude ??
      (device?.source == LocationSource.device ? device!.longitude : null);
  if (kDebugMode && _previewEnabled) return previewMapEvents(now);
  final useCase = ref.watch(getEventsUseCaseProvider);
  final request = latitude == null || longitude == null
      ? useCase()
      : useCase.nearby(
          latitude: latitude,
          longitude: longitude,
          radiusKm: options.radiusKm,
        );
  return request.then(
    (events) => const CurrentAndUpcomingMapEvents()(events, now),
  );
});
