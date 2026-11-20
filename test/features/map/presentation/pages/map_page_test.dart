import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/presentation/controllers/location_controller.dart';
import 'package:frontend/features/location/presentation/controllers/location_state.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:frontend/features/map/presentation/molecules/location_picker.dart';
import 'package:frontend/features/map/presentation/pages/map_page.dart';
import 'package:frontend/features/map/presentation/controllers/map_events_provider.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// La prueba sustituye la plataforma nativa, manteniendo la fachada de Mapbox.
// ignore: depend_on_referenced_packages
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:mocktail/mocktail.dart';

class _TestMap extends Mock implements MapboxMapPlatformInterface {}

class _TestStyle extends Mock implements StylePlatformInterface {}

class _TestPlanRepository extends Mock implements PlanRepository {}

class _TestLogo extends Mock implements LogoSettingsPlatformInterface {}

class _TestAttribution extends Mock
    implements AttributionSettingsPlatformInterface {}

class _TestAnnotations extends Mock
    implements AnnotationManagerPlatformInterface {}

class _TestCircles extends Mock
    implements CircleAnnotationManagerPlatformInterface {}

class _TestLocationController extends LocationController {
  void setLocation(UserLocation location) {
    state = LocationState(status: LocationStatus.ready, location: location);
  }
}

void main() {
  testWidgets('prioriza el punto manual ante GPS tardío y permite volver', (
    tester,
  ) async {
    final controller = _TestLocationController();
    final locations = <CircleAnnotationOptions>[];
    final cameraCenters = <Position>[];
    final deviceMap = _TestMap();
    final annotations = _TestAnnotations();
    final circles = _TestCircles();
    final logo = _TestLogo();
    final attribution = _TestAttribution();
    final center = Point(coordinates: Position(-76.61, 2.44));
    registerFallbackValue(CircleAnnotationOptions(geometry: center));
    registerFallbackValue(CameraOptions());
    registerFallbackValue(LogoSettings());
    registerFallbackValue(AttributionSettings());
    when(() => deviceMap.style).thenReturn(_TestStyle());
    when(() => deviceMap.logo).thenReturn(logo);
    when(() => deviceMap.attribution).thenReturn(attribution);
    when(() => deviceMap.annotations).thenReturn(annotations);
    when(() => deviceMap.setCamera(any())).thenAnswer((invocation) async {
      final options = invocation.positionalArguments.single as CameraOptions;
      cameraCenters.add(options.center!.coordinates);
    });
    when(() => logo.updateSettings(any())).thenAnswer((_) async {});
    when(() => attribution.updateSettings(any())).thenAnswer((_) async {});
    when(() => annotations.createCircleAnnotationManager())
        .thenAnswer((_) async => circles);
    when(() => circles.deleteAll()).thenAnswer((_) async => locations.clear());
    when(() => circles.create(any())).thenAnswer((invocation) async {
      final point =
          invocation.positionalArguments.single as CircleAnnotationOptions;
      locations.add(point);
      return CircleAnnotation(id: 'device', geometry: point.geometry);
    });
    late MapWidget map;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith((ref) async => []),
          locationControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapPage(
              accessToken: 'pk.test',
              mapBuilder: (widget) {
                map = widget;
                return const SizedBox.expand();
              },
              markerWriter: (_) async {},
            ),
          ),
        ),
      ),
    );
    // ignore: invalid_use_of_internal_member
    map.onMapCreated!(MapboxMap(deviceMap));
    map.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(locations, isEmpty);

    expect(find.text('Radio: 5 km'), findsOneWidget);
    await tester.tap(find.text('Radio: 5 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    final radius = ProviderScope.containerOf(
      tester.element(find.byType(Slider)),
    ).read(mapSearchOptionsProvider).radiusKm;
    expect(radius, greaterThan(5));
    Navigator.of(tester.element(find.byType(Slider))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Radio: $radius km'), findsOneWidget);

    await tester.tap(find.text('Elegir ubicación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final picker = tester.widget<LocationPicker>(find.byType(LocationPicker));
    expect(picker.initialPoint, isNull);
    Navigator.of(tester.element(find.byType(LocationPicker)))
        .pop(const EventCoordinates(4.60, -74.08));
    await tester.pumpAndSettle();
    expect(cameraCenters.single.lat, 4.60);
    expect(cameraCenters.single.lng, -74.08);

    controller.setLocation(
      const UserLocation(
        latitude: 2.44,
        longitude: -76.61,
        source: LocationSource.device,
      ),
    );
    await tester.pumpAndSettle();
    final marker = locations.single;
    expect(marker.geometry.coordinates.lat, 2.44);
    expect(marker.geometry.coordinates.lng, -76.61);
    expect(marker.circleStrokeWidth, 3);
    expect(cameraCenters, hasLength(1));
    expect(find.text('Cambiar ubicación manual'), findsOneWidget);

    await tester.tap(find.text('Volver a mi ubicación'));
    await tester.pumpAndSettle();
    expect(cameraCenters, hasLength(2));
    expect(cameraCenters.last.lat, 2.44);
    expect(cameraCenters.last.lng, -76.61);
    expect(find.text('Elegir ubicación'), findsOneWidget);

    controller.setLocation(
      const UserLocation(
        latitude: 2.44,
        longitude: -76.61,
        source: LocationSource.lastKnown,
      ),
    );
    await tester.pumpAndSettle();
    expect(locations, isEmpty);
    expect(find.text('No hay eventos ubicados para mostrar.'), findsOneWidget);
  });

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
    VoidCallback? tapMap;
    final plans = _TestPlanRepository();
    when(() => plans.getMyPlans()).thenAnswer((_) async => <Plan>[]);
    var now = DateTime(2026, 11, 19, 12);
    var currentEvents = <EventSeed>[
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
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapEventsProvider.overrideWith((ref) async => currentEvents),
          planRepositoryProvider.overrideWithValue(plans),
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
              onMapTapReady: (dismiss) => tapMap = dismiss,
              now: () => now,
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
    await tester.ensureVisible(find.text('Guardar en un plan'));
    await tester.tap(find.text('Guardar en un plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Evento: Exposición'), findsOneWidget);
    Navigator.of(tester.element(find.text('Guardado en'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Exposición'), findsOneWidget);

    currentEvents = [
      const EventSeed(
        id: 2,
        title: 'Exposición actualizada',
        category: 'Arte',
        eventText: 'Hoy',
        latitude: 2.4470,
        longitude: -76.6010,
      ),
    ];
    ProviderScope.containerOf(tester.element(find.byType(MapPage)))
        .invalidate(mapEventsProvider);
    await tester.pumpAndSettle();
    expect(find.text('Exposición actualizada'), findsOneWidget);

    tapMap!();
    await tester.pump();
    expect(find.text('Exposición actualizada'), findsOneWidget);
    now = now.add(const Duration(milliseconds: 360));
    tapMap!();
    await tester.pump();
    expect(find.text('Exposición actualizada'), findsNothing);

    selectMarker!({'eventId': 2});
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Cerrar tarjeta del evento'));
    await tester.pump();
    expect(find.text('Exposición actualizada'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
