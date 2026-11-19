import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/event_creation/presentation/organisms/event_location_picker.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

class _MockMap extends Mock implements MapboxMapPlatformInterface {}

class _MockStyle extends Mock implements StylePlatformInterface {}

void main() {
  testWidgets('reintenta la carga y confirma el centro del mapa', (
    tester,
  ) async {
    final map = _MockMap();
    when(() => map.style).thenReturn(_MockStyle());
    late MapWidget mapWidget;
    EventCoordinates? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<EventCoordinates>(
                  MaterialPageRoute(
                    builder: (_) => EventLocationPicker(
                      initialPoint: const EventCoordinates(2, -76),
                      mapBuilder: (widget) {
                        mapWidget = widget;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                );
              },
              child: const Text('Abrir mapa'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir mapa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final confirm = find.widgetWithText(FilledButton, 'Confirmar ubicación');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    final firstKey = mapWidget.key;
    mapWidget.onMapLoadErrorListener!(
      MapLoadingErrorEventData(
        type: MapLoadErrorType.STYLE,
        message: 'Error de carga',
        timestamp: 0,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar mapa'));
    await tester.pump();
    expect(mapWidget.key, isNot(firstKey));

    // ignore: invalid_use_of_internal_member
    mapWidget.onMapCreated!(MapboxMap(map));
    mapWidget.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    when(() => map.getCameraState()).thenThrow(StateError('Sin cámara'));
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('No pudimos seleccionar el punto.'), findsOneWidget);

    when(() => map.getCameraState()).thenAnswer(
      (_) async => CameraState(
        center: Point(coordinates: Position(-76.6147, 2.4448)),
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        zoom: 15,
        bearing: 0,
        pitch: 0,
      ),
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(selected?.latitude, 2.4448);
    expect(selected?.longitude, -76.6147);
  });
}
