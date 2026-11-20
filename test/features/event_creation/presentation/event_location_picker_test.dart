import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/molecules/location_picker.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  testWidgets('reintenta la carga y confirma el centro del mapa', (
    tester,
  ) async {
    CameraState? camera;
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
                    builder: (_) => LocationPicker(
                      initialPoint: const EventCoordinates(2, -76),
                      readCamera: () async =>
                          camera ?? (throw StateError('Sin cámara')),
                      mapBuilder: (widget) {
                        mapWidget = widget;
                        return const SizedBox(key: ValueKey('picker-map'));
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
    final map = find.byKey(const ValueKey('picker-map'));
    final availableMapArea = tester.getSize(map);
    expect(availableMapArea.width, tester.getSize(find.byType(AppBar)).width);
    expect(availableMapArea.height, greaterThan(32));

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

    mapWidget.onMapLoadedListener!(
      MapLoadedEventData(
        timeInterval: EventTimeInterval(
          begin: DateTime(2026),
          end: DateTime(2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(map), availableMapArea);
    expect(
      tester.getCenter(find.byIcon(Icons.my_location)),
      tester.getCenter(map),
    );

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('No pudimos seleccionar el punto.'), findsOneWidget);

    camera = CameraState(
      center: Point(coordinates: Position(-76.6147, 2.4448)),
      padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      zoom: 15,
      bearing: 0,
      pitch: 0,
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(selected?.latitude, 2.4448);
    expect(selected?.longitude, -76.6147);
  });
}
