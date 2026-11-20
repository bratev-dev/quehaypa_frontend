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
    String date;
    if (start == null) {
      final eventText = event.eventText.trim();
      date = eventText.isEmpty ? 'Fecha por confirmar' : eventText;
    } else {
      final timeRange = end != null && _sameDay(start, end)
          ? ' – ${_time(end)}'
          : '';
      date =
          '${_weekdays[start.weekday - 1]} ${start.day} '
          '${_months[start.month - 1]} · ${_time(start)}$timeRange';
    }
    final venue = event.venue?.trim();
    final city = event.city?.trim();
    String place = 'Lugar por confirmar';
    if (venue != null && venue.isNotEmpty) {
      place = venue;
    } else if (city != null && city.isNotEmpty) {
      place = city;
    }
    return MapEventCardDetails(
      when: date,
      where: place,
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
