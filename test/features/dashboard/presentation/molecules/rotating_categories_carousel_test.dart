import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:frontend/features/dashboard/presentation/atoms/category_circle_atom.dart';
import 'package:frontend/features/dashboard/presentation/molecules/rotating_categories_carousel.dart';
import 'package:frontend/features/dashboard/presentation/organisms/header_arc_geometry.dart';

const double _screenWidth = 400;
const double _spacing = _screenWidth / 5;

// Orden de la rueda: General y luego los intereses del controlador.
const List<String> _wheel = [
  'General',
  'Tecnología',
  'Música',
  'Deportes',
  'Arte',
  'Cine',
  'Gastronomía',
];

// Un punto dentro de la zona que responde al dedo (sobre el arco).
const Offset _onArc = Offset(_screenWidth / 2, 240);

Future<void> _pumpCarousel(
  WidgetTester tester, {
  List<String>? interests,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  const geometry = HeaderArcGeometry(
    width: _screenWidth,
    outerEdgeY: 200,
    outerSagitta: 56,
    thickness: 115,
  );

  final container = ProviderContainer();
  addTearDown(container.dispose);
  container
      .read(dashboardControllerProvider.notifier)
      .setUserInterests(interests ?? _wheel.skip(1).toList());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: RotatingCategoriesCarousel(geometry: geometry),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

List<CategoryCircleAtom> _atoms(WidgetTester tester) => tester
    .widgetList<CategoryCircleAtom>(find.byType(CategoryCircleAtom))
    .toList();

CategoryCircleAtom _focusedAtom(WidgetTester tester) =>
    _atoms(tester).singleWhere((atom) => atom.isFocused);

String _selected(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(RotatingCategoriesCarousel)),
  );
  return container.read(dashboardControllerProvider).selectedCategory;
}

// Deja pasar el tiempo de la selección por enfoque (400 ms) con margen.
Future<void> _waitForSelection(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 600));

void main() {
  testWidgets('sin intereses muestra General una sola vez y centrada', (
    tester,
  ) async {
    await _pumpCarousel(tester, interests: []);
    expect(find.text('General'), findsOneWidget);
    await tester.dragFrom(_onArc, const Offset(-_spacing, 0));
    await tester.pumpAndSettle();
    await _waitForSelection(tester);
    expect(find.text('General'), findsOneWidget);
    expect(_selected(tester), 'General');
    expect(
      tester.getCenter(find.byType(CategoryCircleAtom)).dx,
      closeTo(_screenWidth / 2, 0.5),
    );
  });

  testWidgets('empieza con General enfocada en el centro', (tester) async {
    await _pumpCarousel(tester);

    final focused = _focusedAtom(tester);
    expect(focused.label, 'General');
    expect(
      tester.getCenter(find.byWidget(focused)).dx,
      closeTo(_screenWidth / 2, 0.5),
    );
  });

  testWidgets('arrastrar una posición enfoca la siguiente categoría', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    await tester.dragFrom(_onArc, const Offset(-_spacing, 0));
    await tester.pumpAndSettle();

    expect(_focusedAtom(tester).label, 'Tecnología');
    expect(
      tester.getCenter(find.byWidget(_focusedAtom(tester))).dx,
      closeTo(_screenWidth / 2, 0.5),
    );
  });

  testWidgets('arrastrar en sentido contrario retrocede (ciclo infinito)', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    await tester.dragFrom(_onArc, const Offset(_spacing, 0));
    await tester.pumpAndSettle();

    // Antes de la primera (General) está la última de la rueda.
    expect(_focusedAtom(tester).label, _wheel.last);
  });

  testWidgets('soltar a medio camino encaja en la posición más cercana', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    await tester.dragFrom(_onArc, const Offset(-_spacing * 0.7, 0));
    await tester.pumpAndSettle();

    expect(_focusedAtom(tester).label, 'Tecnología');
    expect(
      tester.getCenter(find.byWidget(_focusedAtom(tester))).dx,
      closeTo(_screenWidth / 2, 0.5),
    );
  });

  testWidgets('con impulso la rueda siempre termina exactamente centrada', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    for (final speed in [300.0, 800.0, 1500.0, 3000.0]) {
      await tester.flingFrom(_onArc, const Offset(-120, 0), speed);
      await tester.pumpAndSettle();

      final focused = _focusedAtom(tester);
      expect(
        tester.getCenter(find.byWidget(focused)).dx,
        closeTo(_screenWidth / 2, 0.5),
        reason: 'velocidad $speed',
      );
      await _waitForSelection(tester);
    }
  });

  testWidgets('enfocar selecciona la categoría tras el tiempo de espera', (
    tester,
  ) async {
    await _pumpCarousel(tester);
    expect(_selected(tester), 'General');

    await tester.dragFrom(_onArc, const Offset(-_spacing, 0));
    await tester.pumpAndSettle();

    // Recién enfocada todavía no está seleccionada.
    expect(_selected(tester), 'General');

    await _waitForSelection(tester);
    expect(_selected(tester), 'Tecnología');
  });

  testWidgets('tocar una categoría de un costado la trae al centro', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    await tester.tap(find.text('Música'));
    await tester.pumpAndSettle();

    expect(_focusedAtom(tester).label, 'Música');
    expect(
      tester.getCenter(find.byWidget(_focusedAtom(tester))).dx,
      closeTo(_screenWidth / 2, 0.5),
    );

    await _waitForSelection(tester);
    expect(_selected(tester), 'Música');
  });

  testWidgets('tras una vuelta completa regresa a la primera categoría', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    for (var i = 1; i <= _wheel.length; i++) {
      await tester.dragFrom(_onArc, const Offset(-_spacing, 0));
      await tester.pumpAndSettle();
      expect(_focusedAtom(tester).label, _wheel[i % _wheel.length]);
    }

    await _waitForSelection(tester);
    expect(_selected(tester), 'General');
  });
}
