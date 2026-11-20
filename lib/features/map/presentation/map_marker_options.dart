import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../preferences/domain/entities/event_seed.dart';
import '../domain/entities/event_map_marker.dart';

class MapPinImages {
  const MapPinImages({
    required this.blue,
    required this.pink,
    required this.yellow,
  });

  final Uint8List blue;
  final Uint8List pink;
  final Uint8List yellow;

  static Future<MapPinImages> load() async {
    Future<Uint8List> bytes(String name) async =>
        (await rootBundle.load('assets/images/map_pin_$name.png')).buffer
            .asUint8List();
    final images = await Future.wait([
      bytes('blue'),
      bytes('pink'),
      bytes('yellow'),
    ]);
    return MapPinImages(blue: images[0], pink: images[1], yellow: images[2]);
  }

  Uint8List forCategory(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.contains('música') || normalized.contains('musica')) {
      return blue;
    }
    if (normalized.contains('arte')) return pink;
    return yellow;
  }
}

/// Cada opción conserva el ID del evento y ancla la punta en sus coordenadas.
List<PointAnnotationOptions> mapMarkerOptions(
  Iterable<EventSeed> events,
  MapPinImages images,
) => events
    .map((event) {
      final marker = EventMapMarker.fromEvent(event);
      if (marker == null) return null;
      return PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            marker.coordinates.longitude,
            marker.coordinates.latitude,
          ),
        ),
        image: images.forCategory(event.category),
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.5,
        customData: {'eventId': event.id},
      );
    })
    .whereType<PointAnnotationOptions>()
    .toList();
