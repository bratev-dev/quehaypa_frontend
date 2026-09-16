import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/dashboard_controller.dart';
import '../atoms/category_circle_atom.dart';
import '../organisms/header_arc_geometry.dart';

/// Ancho reservado para cada ítem (círculo + etiqueta), igual al que ya usa
/// [CategoryCircleAtom] internamente para su etiqueta.
const double _itemWidth = 65;

/// Alto que ocupa la etiqueta bajo el círculo dentro de [CategoryCircleAtom]:
/// 6 px de separación + una línea de texto de 11 px. Se descuenta al ubicar
/// el ítem para centrar el conjunto (círculo + etiqueta) sobre la línea media
/// del arco; si solo se centrara el círculo, el texto queda pegado al borde
/// inferior de la franja.
const double _labelHeight = 20;

class RotatingCategoriesCarousel extends ConsumerWidget {
  /// Este widget se posiciona ocupando el header completo (`Positioned.fill`
  /// dentro del `Stack` de `DashboardHeader`), así que las coordenadas de
  /// [geometry] se usan directamente, sin conversión.
  final HeaderArcGeometry geometry;

  const RotatingCategoriesCarousel({super.key, required this.geometry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    final interests = state.userInterests;
    final offset = state.revolverRotationOffset;

    String getInterestAt(int index) {
      if (interests.isEmpty) return 'Interés';
      final actualIndex = (offset + index) % interests.length;
      return interests[actualIndex];
    }

    IconData getIconForCategory(String category) {
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

    final cat0 = getInterestAt(0);
    final cat1 = getInterestAt(1);
    final cat2 = getInterestAt(2);
    final cat3 = getInterestAt(3);

    // Los 5 ítems (4 categorías + "General" en el centro) se reparten en
    // partes iguales del ancho, y cada uno se centra sobre la línea media
    // del arco en su posición horizontal: geometry.centerlineY(x). Así, si
    // mañana cambia la curvatura o el grosor del arco (HeaderArcGeometry),
    // los círculos se reacomodan solos.
    Widget buildPositionedItem({
      required String category,
      required int index,
      bool isGeneral = false,
    }) {
      final circleSize = isGeneral ? 68.0 : 52.0;
      final x = geometry.width * (index + 0.5) / 5;
      final centerY = geometry.centerlineY(x);

      final circle = isGeneral
          ? CategoryCircleAtom(
              label: category,
              icon: getIconForCategory(category),
              isGeneral: true,
              isSelected: state.selectedCategory == category,
              onTap: () => controller.selectCategory(category),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: CategoryCircleAtom(
                key: ValueKey<String>(category),
                label: category,
                icon: getIconForCategory(category),
                isSelected: state.selectedCategory == category,
                onTap: () => controller.selectCategory(category),
              ),
            );

      return Positioned(
        left: x - _itemWidth / 2,
        // Se centra el conjunto completo (círculo + etiqueta) sobre la línea
        // media del arco, no solo el círculo.
        top: centerY - (circleSize + _labelHeight) / 2,
        width: _itemWidth,
        child: circle,
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          controller.rotateRevolver(true);
        } else if (details.primaryVelocity! > 0) {
          controller.rotateRevolver(false);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          buildPositionedItem(category: cat0, index: 0),
          buildPositionedItem(category: cat1, index: 1),
          buildPositionedItem(category: 'General', index: 2, isGeneral: true),
          buildPositionedItem(category: cat2, index: 3),
          buildPositionedItem(category: cat3, index: 4),
        ],
      ),
    );
  }
}
