import '../../../preferences/domain/entities/event_seed.dart';

/// Eventos en curso o próximos, sin incluir los que ya terminaron.
class CurrentAndUpcomingMapEvents {
  const CurrentAndUpcomingMapEvents();

  List<EventSeed> call(List<EventSeed> events, DateTime now) =>
      events.where((event) {
        final startsAt = DateTime.tryParse(event.startsAt ?? '');
        final endsAt = DateTime.tryParse(event.endsAt ?? '');
        if (startsAt == null) return false;
        if (endsAt == null) return !startsAt.isBefore(now);
        return endsAt.isAfter(startsAt) && endsAt.isAfter(now);
      }).toList();
}
