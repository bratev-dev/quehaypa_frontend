import '../../../preferences/domain/entities/event_seed.dart';
import 'event_coordinates.dart';

class EventMapMarker {
  const EventMapMarker({required this.eventId, required this.coordinates});

  final int eventId;
  final EventCoordinates coordinates;

  static EventMapMarker? fromEvent(EventSeed event) {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) return null;
    final coordinates = EventCoordinates(latitude, longitude);
    if (!coordinates.isValid) return null;
    return EventMapMarker(eventId: event.id, coordinates: coordinates);
  }
}
