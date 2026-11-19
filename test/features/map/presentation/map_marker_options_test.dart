import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:frontend/features/map/domain/entities/event_map_marker.dart';
import 'package:frontend/features/map/presentation/map_marker_options.dart';

void main() {
  test('dibuja un círculo amarillo con borde oscuro en cada coordenada', () {
    final options = mapMarkerOptions([
      const EventMapMarker(
        eventId: 1,
        coordinates: EventCoordinates(2.4419, -76.6063),
      ),
      const EventMapMarker(
        eventId: 2,
        coordinates: EventCoordinates(2.4470, -76.6010),
      ),
    ]);

    expect(options, hasLength(2));
    expect(options.first.geometry.coordinates.lat, 2.4419);
    expect(options.first.geometry.coordinates.lng, -76.6063);
    expect(options.first.circleColor, 0xFFFCD413);
    expect(options.first.circleRadius, 11);
    expect(options.first.circleStrokeColor, 0xFF121212);
    expect(options.first.circleStrokeWidth, 3);
    expect(options.last.geometry.coordinates.lat, 2.4470);
  });
}
