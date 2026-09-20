import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/presentation/organisms/dashboard_header.dart';
import 'package:frontend/features/dashboard/presentation/organisms/header_arc_geometry.dart';

void main() {
  group('HeaderArcGeometry con arco plano (sagitta 0)', () {
    const flat = HeaderArcGeometry(
      width: 400,
      outerEdgeY: 0,
      outerSagitta: 0,
      thickness: 162,
      topInset: 47,
    );

    test(
      'la franja es un rectángulo finito y el recorte cubre todo el header',
      () {
        expect(flat.isFlat, isTrue);
        expect(
          flat.ringPath().getBounds(),
          const Rect.fromLTWH(0, 0, 400, 162),
        );
        expect(
          flat.innerArcPath().getBounds(),
          const Rect.fromLTWH(0, 0, 400, 162),
        );
      },
    );

    test('los círculos se centran bajo la zona del notch', () {
      expect(flat.centerlineY(200), 47 + (162 - 47) / 2);
    });

    test('con arco, la línea media sigue el arco y sube en el centro', () {
      const curved = HeaderArcGeometry(
        width: 400,
        outerEdgeY: 200,
        outerSagitta: 56,
        thickness: 115,
      );

      expect(curved.isFlat, isFalse);
      expect(curved.centerlineY(200), closeTo(144 + 115 / 2, 1e-6));
      expect(curved.centerlineY(0), closeTo(200 + 115 / 2, 1e-6));
    });
  });

  group('DashboardHeaderDelegate', () {
    test('el rango de colapso no depende del notch', () {
      const withNotch = DashboardHeaderDelegate(topInset: 47);
      const withoutNotch = DashboardHeaderDelegate(topInset: 0);

      expect(withNotch.maxExtent - withNotch.minExtent, 221);
      expect(withoutNotch.maxExtent - withoutNotch.minExtent, 221);
      expect(withNotch.minExtent, 47 + 115);
    });

    testWidgets('colapsa a la franja fija y reaparece el arco al volver', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 141);
      tester.view.viewPadding = const FakeViewPadding(top: 141);
      addTearDown(tester.view.reset);

      const delegate = DashboardHeaderDelegate(topInset: 47);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const SliverPersistentHeader(
                    pinned: true,
                    delegate: delegate,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          SizedBox(height: 200, child: Text('Item $index')),
                      childCount: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final headerClip = find
          .descendant(
            of: find.byType(SliverPersistentHeader),
            matching: find.byType(ClipPath),
          )
          .first;

      expect(tester.getSize(headerClip).height, delegate.maxExtent);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerClip).height, delegate.minExtent);
      expect(tester.getTopLeft(headerClip).dy, 0);

      // Regresión: con sagitta 0 el recorte degeneraba y el header dejaba de
      // pintar el arco y las categorías.
      final clipper = tester.widget<ClipPath>(headerClip).clipper!;
      final clipBounds = clipper
          .getClip(tester.getSize(headerClip))
          .getBounds();
      expect(clipBounds.isFinite, isTrue);
      expect(clipBounds.height, delegate.minExtent);
      expect(find.text('General'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 4000));
      await tester.pumpAndSettle();

      expect(tester.getSize(headerClip).height, delegate.maxExtent);
    });

    // Con medidas fraccionarias (como un Android real) el alto dibujado debe
    // ser idéntico al que reserva el sliver; si difiere por redondeo, Flutter
    // lanza "layoutExtent exceeds paintExtent".
    testWidgets(
      'con notch fraccionario no hay errores de geometría del sliver',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        tester.view.padding = const FakeViewPadding(top: 93);
        tester.view.viewPadding = const FakeViewPadding(top: 93);
        addTearDown(tester.view.reset);

        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: DashboardHeaderDelegate(topInset: 93 / 2.75),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            SizedBox(height: 200, child: Text('Item $index')),
                        childCount: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        for (var offset = 0.0; offset <= 230; offset += 0.7) {
          controller.jumpTo(offset);
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'offset $offset');
        }
      },
    );
  });
}
