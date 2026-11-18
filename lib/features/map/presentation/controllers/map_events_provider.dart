import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preferences/domain/entities/event_seed.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../domain/usecases/current_and_upcoming_map_events.dart';

const _previewEnabled = bool.fromEnvironment('MAP_EVENTS_PREVIEW');

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
  if (kDebugMode && _previewEnabled) return previewMapEvents(now);
  return ref
      .watch(getEventsUseCaseProvider)()
      .then((events) => const CurrentAndUpcomingMapEvents()(events, now));
});
