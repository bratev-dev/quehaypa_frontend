import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/map_marker_options.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final blue = Uint8List.fromList([1]);
  final pink = Uint8List.fromList([2]);
  final yellow = Uint8List.fromList([3]);
  final images = MapPinImages(blue: blue, pink: pink, yellow: yellow);

  test('dibuja pines por categoría y ancla la punta a las coordenadas', () {
    final options = mapMarkerOptions([
      const EventSeed(
        id: 1,
        title: 'Concierto',
        category: 'Música',
        eventText: '',
        latitude: 2.4419,
        longitude: -76.6063,
      ),
      const EventSeed(
        id: 2,
        title: 'Exposición',
        category: 'Arte',
        eventText: '',
        latitude: 2.4470,
        longitude: -76.6010,
      ),
      const EventSeed(
        id: 3,
        title: 'Cine',
        category: 'Cultura',
        eventText: '',
        latitude: 2.4480,
        longitude: -76.6020,
      ),
      const EventSeed(
        id: 4,
        title: 'Sin ubicación',
        category: 'Arte',
        eventText: '',
      ),
    ], images);

    expect(options, hasLength(3));
    expect(options.first.geometry.coordinates.lat, 2.4419);
    expect(options.first.geometry.coordinates.lng, -76.6063);
    expect(options.first.iconAnchor, IconAnchor.BOTTOM);
    expect(options.first.image, blue);
    expect(options[1].image, pink);
    expect(options[2].image, yellow);
    expect(options.first.customData, {'eventId': 1});
    expect(options[1].customData, {'eventId': 2});
  });

  test('carga tres imágenes PNG válidas para Mapbox', () async {
    final loaded = await MapPinImages.load();
    for (final image in [loaded.blue, loaded.pink, loaded.yellow]) {
      expect(image.length, greaterThan(100));
      expect(image.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    }
  });
}
