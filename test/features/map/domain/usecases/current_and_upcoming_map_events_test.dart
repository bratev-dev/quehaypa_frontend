import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/domain/usecases/current_and_upcoming_map_events.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';

void main() {
  final now = DateTime(2026, 11, 18, 18);

  EventSeed event(int id, DateTime? start, DateTime? end) => EventSeed(
    id: id,
    title: 'Evento $id',
    category: 'Música',
    eventText: '',
    startsAt: start?.toIso8601String(),
    endsAt: end?.toIso8601String(),
  );

  test('muestra eventos en curso y próximos, pero no los terminados', () {
    final events = [
      event(
        1,
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      ),
      event(
        2,
        now.add(const Duration(minutes: 1)),
        now.add(const Duration(hours: 2)),
      ),
      event(3, now.subtract(const Duration(hours: 2)), now),
      event(4, now.subtract(const Duration(hours: 1)), null),
      event(5, now.add(const Duration(minutes: 1)), null),
    ];

    expect(const CurrentAndUpcomingMapEvents()(events, now).map((e) => e.id), [
      1,
      2,
      5,
    ]);
  });
}
