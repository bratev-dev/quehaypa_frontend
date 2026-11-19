import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../domain/entities/event_map_marker.dart';

/// Traduce los eventos ubicados a las anotaciones visibles de Mapbox.
List<CircleAnnotationOptions> mapMarkerOptions(
  Iterable<EventMapMarker> markers,
) => markers
    .map(
      (marker) => CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            marker.coordinates.longitude,
            marker.coordinates.latitude,
          ),
        ),
        circleColor: const Color(0xFFFCD413).toARGB32(),
        circleRadius: 11,
        circleStrokeColor: const Color(0xFF121212).toARGB32(),
        circleStrokeWidth: 3,
      ),
    )
    .toList();
