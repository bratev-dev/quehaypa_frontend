import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/pages/map_page.dart';
import 'package:frontend/features/map/presentation/controllers/map_events_provider.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  Future<void> pumpMap(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      overrides: [mapEventsProvider.overrideWith((ref) async => [])],
      child: child,
    ),
  );

  testWidgets('sin token muestra una explicación y no crea el mapa', (
    tester,
  ) async {
    await pumpMap(
      tester,
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

    await pumpMap(
      tester,
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

  testWidgets('sin eventos ubicados muestra un estado vacío', (tester) async {
    await pumpMap(
      tester,
      MaterialApp(
        home: Scaffold(
          body: MapPage(
            accessToken: 'pk.test',
            mapBuilder: (_) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No hay eventos ubicados para mostrar.'), findsOneWidget);
  });

  testWidgets('un fallo inicial muestra reintento y crea un mapa nuevo', (
    tester,
  ) async {
    MapWidget? currentMap;

    await pumpMap(
      tester,
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

    await pumpMap(
      tester,
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

  testWidgets('envía un marcador por evento ubicado al cargar el mapa', (
    tester,
  ) async {
    MapWidget? createdMap;
    List<PointAnnotationOptions>? written;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith(
            (ref) async => [
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
                title: 'Sin ubicación',
                category: 'Arte',
                eventText: '',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapPage(
              accessToken: 'pk.test',
              mapBuilder: (map) {
                createdMap = map;
                return const SizedBox.expand();
              },
              markerWriter: (options) async => written = options,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    createdMap!.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(written, hasLength(1));
    expect(written!.single.geometry.coordinates.lat, 2.4419);
    expect(find.text('No hay eventos ubicados para mostrar.'), findsNothing);
  });

  testWidgets('permite reintentar si falla el envío de marcadores', (
    tester,
  ) async {
    MapWidget? createdMap;
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith(
            (ref) async => [
              const EventSeed(
                id: 1,
                title: 'Concierto',
                category: 'Música',
                eventText: '',
                latitude: 2.4419,
                longitude: -76.6063,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapPage(
              accessToken: 'pk.test',
              mapBuilder: (map) {
                createdMap = map;
                return const SizedBox.expand();
              },
              markerWriter: (_) async {
                attempts++;
                if (attempts == 1) throw Exception('Anotación fallida');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    createdMap!.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No pudimos mostrar los eventos.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('No pudimos mostrar los eventos.'), findsNothing);
  });

  testWidgets('un error de consulta muestra la opción de reintento', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith(
            (ref) async => throw Exception('offline'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapPage(
              accessToken: 'pk.test',
              mapBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos mostrar los eventos.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos mostrar los eventos.'), findsOneWidget);
  });

  testWidgets('selecciona, cambia y cierra la tarjeta de un marcador', (
    tester,
  ) async {
    MapWidget? createdMap;
    void Function(Map<String, Object>?)? selectMarker;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith(
            (ref) async => [
              const EventSeed(
                id: 1,
                title: 'Concierto',
                category: 'Música',
                eventText: 'Hoy',
                venue: 'Teatro Municipal',
                latitude: 2.4419,
                longitude: -76.6063,
              ),
              const EventSeed(
                id: 2,
                title: 'Exposición',
                category: 'Arte',
                eventText: 'Mañana',
                city: 'Popayán',
                latitude: 2.4470,
                longitude: -76.6010,
                isPaid: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapPage(
              accessToken: 'pk.test',
              mapBuilder: (map) {
                createdMap = map;
                return const SizedBox.expand();
              },
              markerWriter: (_) async {},
              onMarkerTapReady: (select) => selectMarker = select,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    createdMap!.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    selectMarker!({'eventId': 1});
    await tester.pump();
    expect(find.text('Concierto'), findsOneWidget);
    expect(find.text('Teatro Municipal'), findsOneWidget);
    expect(find.text('Gratuito'), findsOneWidget);

    selectMarker!({'eventId': 2});
    await tester.pump();
    expect(find.text('Concierto'), findsNothing);
    expect(find.text('Exposición'), findsOneWidget);
    expect(find.text('De pago'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cerrar tarjeta del evento'));
    await tester.pump();
    expect(find.text('Exposición'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
