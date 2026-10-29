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

  testWidgets('con token configura el mapa base centrado en Popayán', (
    tester,
  ) async {
    MapWidget? createdMap;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            accessToken: 'pk.test',
            mapBuilder: (map) {
              createdMap = map;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    expect(createdMap, isNotNull);
    expect(createdMap!.styleUri, MapboxStyles.STANDARD);
    final viewport = createdMap!.viewport! as CameraViewportState;
    expect(viewport.zoom, 13);
    expect(viewport.center!.coordinates.lng, -76.6063);
    expect(viewport.center!.coordinates.lat, 2.4419);
    expect(find.text('No pudimos cargar el mapa.'), findsNothing);
  });

  testWidgets('un fallo inicial muestra reintento y crea un mapa nuevo', (
    tester,
  ) async {
    MapWidget? currentMap;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            accessToken: 'pk.test',
            mapBuilder: (map) {
              currentMap = map;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    final firstMap = currentMap!;
    firstMap.onMapLoadErrorListener!(
      MapLoadingErrorEventData(
        type: MapLoadErrorType.STYLE,
        message: 'Error de carga',
        timestamp: 0,
      ),
    );
    await tester.pump();

    expect(find.text('No pudimos cargar el mapa.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(find.text('No pudimos cargar el mapa.'), findsNothing);
    expect(currentMap!.key, isNot(firstMap.key));
  });

  testWidgets('al cargar se quita el error y se ignoran fallos posteriores', (
    tester,
  ) async {
    MapWidget? currentMap;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            accessToken: 'pk.test',
            mapBuilder: (map) {
              currentMap = map;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    final error = MapLoadingErrorEventData(
      type: MapLoadErrorType.STYLE,
      message: 'Error de carga',
      timestamp: 0,
    );
    currentMap!.onMapLoadErrorListener!(error);
    await tester.pump();
    expect(find.text('No pudimos cargar el mapa.'), findsOneWidget);

    currentMap!.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No pudimos cargar el mapa.'), findsNothing);

    currentMap!.onMapLoadErrorListener!(error);
    await tester.pump();
    expect(find.text('No pudimos cargar el mapa.'), findsNothing);
  });
}
