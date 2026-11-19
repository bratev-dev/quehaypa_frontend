import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/map_event_selection.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';

void main() {
  const events = [
    EventSeed(id: 1, title: 'Concierto', category: 'Música', eventText: ''),
    EventSeed(id: 2, title: 'Exposición', category: 'Arte', eventText: ''),
  ];

  test('encuentra el evento asociado al marcador seleccionado', () {
    expect(eventForMarkerTap(events, {'eventId': 2})?.title, 'Exposición');
    expect(eventForMarkerTap(events, {'eventId': 1})?.title, 'Concierto');
  });

  test('ignora marcadores sin un identificador de evento válido', () {
    expect(eventForMarkerTap(events, null), isNull);
    expect(eventForMarkerTap(events, {'eventId': '1'}), isNull);
    expect(eventForMarkerTap(events, {'eventId': 3}), isNull);
  });

  test('prioriza el ID de la anotación creada por Mapbox', () {
    expect(
      eventForAnnotationTap(events, 'pin-2', {'pin-2': 2}, {'eventId': 1})?.id,
      2,
    );
    expect(eventForAnnotationTap(events, 'sin-id', {}, {'eventId': 1})?.id, 1);
  });
}
