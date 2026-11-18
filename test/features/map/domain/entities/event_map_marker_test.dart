import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/domain/entities/event_map_marker.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';

void main() {
  EventSeed event(double? latitude, double? longitude) => EventSeed(
    id: 7,
    title: 'Concierto',
    category: 'Música',
    eventText: '',
    latitude: latitude,
    longitude: longitude,
  );

  test('crea un marcador para un evento con coordenadas válidas', () {
    final marker = EventMapMarker.fromEvent(event(2.4419, -76.6063));
    expect(marker?.eventId, 7);
    expect(marker?.coordinates.latitude, 2.4419);
    expect(marker?.coordinates.longitude, -76.6063);
  });

  test('omite eventos anteriores e invalidos sin inventar posiciones', () {
    expect(EventMapMarker.fromEvent(event(null, null)), isNull);
    expect(EventMapMarker.fromEvent(event(2.4, null)), isNull);
    expect(EventMapMarker.fromEvent(event(91, -76)), isNull);
    expect(EventMapMarker.fromEvent(event(double.nan, -76)), isNull);
  });
}
