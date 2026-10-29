import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/pages/map_page.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  testWidgets('sin token muestra una explicación y no crea el mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MapPage(accessToken: '')),
      ),
    );

    expect(
      find.text(
        'Falta configurar el token público de Mapbox para mostrar el mapa.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MapWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
