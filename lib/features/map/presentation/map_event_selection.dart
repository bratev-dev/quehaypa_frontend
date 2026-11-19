import '../../preferences/domain/entities/event_seed.dart';

/// Resuelve el evento asociado al identificador guardado en la anotación.
EventSeed? eventForMarkerTap(
  Iterable<EventSeed> events,
  Map<String, Object>? customData,
) {
  final eventId = customData?['eventId'];
  if (eventId is! int) return null;
  for (final event in events) {
    if (event.id == eventId) return event;
  }
  return null;
}

EventSeed? eventForAnnotationTap(
  Iterable<EventSeed> events,
  String annotationId,
  Map<String, int> eventIdsByAnnotation,
  Map<String, Object>? customData,
) {
  final eventId = eventIdsByAnnotation[annotationId];
  return eventForMarkerTap(
    events,
    eventId == null ? customData : {'eventId': eventId},
  );
}
