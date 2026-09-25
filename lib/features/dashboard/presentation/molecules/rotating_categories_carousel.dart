import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/dashboard_controller.dart';
import '../atoms/category_circle_atom.dart';
import '../organisms/header_arc_geometry.dart';

/// Ancho reservado para cada ítem (círculo + etiqueta), igual al que ya usa
/// [CategoryCircleAtom] internamente para su etiqueta.
const double _itemWidth = 65;

/// Alto que ocupa la etiqueta bajo el círculo dentro de [CategoryCircleAtom]:
/// 6 px de separación + una línea de texto de 11 px.
const double _labelHeight = 20;

/// Alto del ítem completo. El círculo ocupa siempre su caja más grande
/// ([CategoryCircleAtom.focusedSize]), así que el alto no cambia al enfocar.
const double _itemHeight = CategoryCircleAtom.focusedSize + _labelHeight;

/// Categorías que caben a lo ancho de la pantalla: arrastrar 1/5 del ancho
/// avanza una categoría.
const int _itemsPerScreen = 5;

/// Posiciones que se dibujan a cada lado del centro. Con 3 basta: las de los
/// extremos ya están fuera de la pantalla y el recorte del header las corta.
const int _visibleSpan = 3;

/// Tiempo que una categoría debe permanecer enfocada para quedar seleccionada.
const Duration _selectionDelay = Duration(milliseconds: 400);

/// Cuántas posiciones recorre la rueda por cada (posición/s) de velocidad con
/// la que se suelta: es la "fricción" del revólver.
const double _flingTravel = 0.25;

/// Por debajo de esta velocidad (posiciones/s) no hay impulso: solo encaja en
/// la posición más cercana.
const double _minFlingVelocity = 0.8;

/// Ruleta de categorías tipo revólver sobre el arco del header.
///
/// El estado es un único número decimal, [_controller], que es la rotación
/// medida en posiciones. La categoría `n` se dibuja a `n - rotación` posiciones
/// del centro, sobre la línea media del arco ([HeaderArcGeometry.centerlineY]).
/// La rueda es infinita: la categoría de la posición `n` es `n mod total`.
class RotatingCategoriesCarousel extends ConsumerStatefulWidget {
  /// Este widget se posiciona ocupando el header completo (`Positioned.fill`
  /// dentro del `Stack` de `DashboardHeader`), así que las coordenadas de
  /// [geometry] se usan directamente, sin conversión.
  final HeaderArcGeometry geometry;

  const RotatingCategoriesCarousel({super.key, required this.geometry});

  @override
  ConsumerState<RotatingCategoriesCarousel> createState() =>
      _RotatingCategoriesCarouselState();
}

class _RotatingCategoriesCarouselState
    extends ConsumerState<RotatingCategoriesCarousel>
    with SingleTickerProviderStateMixin {
  // Sin límites: la rotación crece o decrece indefinidamente.
  late final AnimationController _controller;
  Timer? _selectionTimer;

  /// Posición absoluta enfocada la última vez que se revisó.
  int _focused = 0;

  double get _spacing => widget.geometry.width / _itemsPerScreen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(_onRotationChanged);
  }

  @override
  void dispose() {
    _selectionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<String> _items() => [
    'General',
    ...ref.read(dashboardControllerProvider).userInterests,
  ];

  void _onRotationChanged() {
    final focused = _controller.value.round();
    if (focused == _focused) return;

    _focused = focused;
    _selectionTimer?.cancel();
    _selectionTimer = Timer(_selectionDelay, _selectFocused);
  }

  void _selectFocused() {
    final items = _items();
    ref
        .read(dashboardControllerProvider.notifier)
        .selectCategory(items[_focused % items.length]);
  }

  void _onDragStart(DragStartDetails details) => _controller.stop();

  void _onDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.delta.dx / _spacing;
  }

  void _onDragEnd(DragEndDetails details) {
    _settle(-details.velocity.pixelsPerSecond.dx / _spacing);
  }

  /// Suelta la rueda con [velocity] (posiciones/s) y la deja encajar en una
  /// posición exacta con un único movimiento que va frenando.
  void _settle(double velocity) {
    final start = _controller.value;

    if (!velocity.isFinite || velocity.abs() < _minFlingVelocity) {
      _animateTo(start.roundToDouble(), const Duration(milliseconds: 250));
      return;
    }

    final target = (start + velocity * _flingTravel).roundToDouble();
    // easeOutCubic arranca con pendiente 3; con esta duración la rueda parte a
    // la misma velocidad con la que se soltó el dedo.
    final seconds = (3 * (target - start).abs() / velocity.abs()).clamp(
      0.25,
      1.2,
    );
    _animateTo(target, Duration(milliseconds: (seconds * 1000).round()));
  }

  void _onItemTap(int index) {
    final distance = (index - _controller.value).abs();
    final millis = (250 + 60 * distance).round().clamp(250, 500);
    _animateTo(index.toDouble(), Duration(milliseconds: millis));
  }

  void _animateTo(double target, Duration duration) {
    if ((target - _controller.value).abs() < 1e-6) return;
    _controller.animateTo(
      target,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'tecnología':
        return Icons.computer_outlined;
      case 'música':
        return Icons.music_note_outlined;
      case 'deportes':
        return Icons.sports_soccer_outlined;
      case 'arte':
        return Icons.palette_outlined;
      case 'cine':
        return Icons.movie_outlined;
      case 'gastronomía':
        return Icons.restaurant_outlined;
      default:
        return Icons.star_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final items = ['General', ...state.userInterests];

    final geometry = widget.geometry;
    // La zona que responde al dedo va desde la cima del arco (centro) hasta su
    // borde inferior (costados); ahí caben todos los ítems.
    final bandTop = geometry.outerEdgeY - geometry.outerSagitta;
    final bandHeight = geometry.bottomAtSides - bandTop;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: bandTop,
          height: bandHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Con `down` la rueda sigue al dedo desde que lo apoya, sin perder
            // el recorrido inicial del umbral de arrastre.
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: () => _settle(0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: _buildItems(items, state.selectedCategory, bandTop),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(
    List<String> items,
    String selectedCategory,
    double bandTop,
  ) {
    final geometry = widget.geometry;
    final rotation = _controller.value;
    final base = rotation.round();

    return [
      for (var k = -_visibleSpan; k <= _visibleSpan; k++)
        _buildItem(
          index: base + k,
          isFocused: k == 0,
          rotation: rotation,
          items: items,
          selectedCategory: selectedCategory,
          geometry: geometry,
          bandTop: bandTop,
        ),
    ];
  }

  Widget _buildItem({
    required int index,
    required bool isFocused,
    required double rotation,
    required List<String> items,
    required String selectedCategory,
    required HeaderArcGeometry geometry,
    required double bandTop,
  }) {
    final x = geometry.width / 2 + (index - rotation) * _spacing;
    final centerY = geometry.centerlineY(x);
    final category = items[index % items.length];

    // La llave por posición absoluta conserva el estado (y la animación de
    // tamaño) de cada ítem mientras la rueda avanza.
    return Positioned(
      key: ValueKey<int>(index),
      left: x - _itemWidth / 2,
      top: centerY - _itemHeight / 2 - bandTop,
      width: _itemWidth,
      child: CategoryCircleAtom(
        label: category,
        icon: _iconFor(category),
        isGeneral: category == 'General',
        isFocused: isFocused,
        isSelected: selectedCategory == category,
        onTap: () => _onItemTap(index),
      ),
    );
  }
}
