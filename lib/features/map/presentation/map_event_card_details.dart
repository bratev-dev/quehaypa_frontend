import '../../preferences/domain/entities/event_seed.dart';

class MapEventCardDetails {
  const MapEventCardDetails({
    required this.when,
    required this.where,
    required this.price,
    required this.adultsOnly,
  });

  final String when;
  final String where;
  final String price;
  final bool adultsOnly;

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  factory MapEventCardDetails.fromEvent(EventSeed event) {
    final start = DateTime.tryParse(event.startsAt ?? '')?.toLocal();
    final end = DateTime.tryParse(event.endsAt ?? '')?.toLocal();
    final date = start == null
        ? (event.eventText.trim().isEmpty
              ? 'Fecha por confirmar'
              : event.eventText.trim())
        : '${_weekdays[start.weekday - 1]} ${start.day} '
              '${_months[start.month - 1]} · ${_time(start)}'
              '${end != null && _sameDay(start, end) ? ' – ${_time(end)}' : ''}';
    final venue = event.venue?.trim();
    final city = event.city?.trim();
    return MapEventCardDetails(
      when: date,
      where: venue != null && venue.isNotEmpty
          ? venue
          : city != null && city.isNotEmpty
          ? city
          : 'Lugar por confirmar',
      price: event.isPaid ? 'De pago' : 'Gratuito',
      adultsOnly: event.audience == 'ADULTS_ONLY',
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'a. m.' : 'p. m.';
    return '$hour:$minute $period';
  }
}
