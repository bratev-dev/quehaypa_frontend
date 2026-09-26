import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/animations/slide_page_route.dart';
import 'package:frontend/features/navigation/presentation/organisms/sliding_navigation_stack.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'ruta desliza y permite volver; movimiento reducido: $reduceMotion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    SlidePageRoute<void>(
                      builder: (_) => const Scaffold(
                        backgroundColor: Colors.black,
                        body: Center(child: Text('Destino')),
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final slides = find.ancestor(
          of: find.text('Destino'),
          matching: find.byType(SlideTransition),
        );
        if (reduceMotion) {
          expect(slides, findsNothing);
        } else {
          final slide = tester.widget<SlideTransition>(slides.first);
          expect(slide.position.value.dx, inExclusiveRange(0.0, 1.0));
        }
        expect(
          find.ancestor(
            of: find.text('Destino'),
            matching: find.byType(FadeTransition),
          ),
          findsNothing,
        );
        await tester.pumpAndSettle();
        expect(find.text('Destino'), findsOneWidget);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(find.text('Destino'), findsNothing);
        expect(find.text('Abrir'), findsOneWidget);
      },
    );

    testWidgets(
      'pestañas conservan datos y ocultan la anterior; movimiento reducido: $reduceMotion',
      (tester) async {
        var index = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  body: Column(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => index = 1 - index),
                        child: const Text('Cambiar'),
                      ),
                      Expanded(
                        child: SlidingNavigationStack(
                          index: index,
                          children: const [
                            TextField(key: ValueKey('nombre')),
                            Center(child: Text('Perfil')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'Juan');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.tap(find.text('Cambiar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Perfil'), findsOneWidget);
        if (reduceMotion) expect(find.byType(TextField), findsNothing);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        await tester.tap(find.text('Cambiar'));
        await tester.pumpAndSettle();
        expect(find.text('Juan'), findsOneWidget);
        expect(find.text('Perfil'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
