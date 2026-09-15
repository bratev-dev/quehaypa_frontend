import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/dashboard_controller.dart';
import '../atoms/category_circle_atom.dart';

class RotatingCategoriesCarousel extends ConsumerWidget {
  const RotatingCategoriesCarousel({super.key});

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

    // Widget auxiliar para animar la transición del ítem cuando rota
    Widget buildAnimatedItem(String category, double verticalOffset) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Transform.translate(
          key: ValueKey<String>(
            category,
          ), // Clave única para que detecte el cambio y anime
          offset: Offset(0, verticalOffset),
          child: CategoryCircleAtom(
            label: category,
            icon: getIconForCategory(category),
            isSelected: state.selectedCategory == category,
            onTap: () => controller.selectCategory(category),
          ),
        ),
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
      child: SizedBox(
        height: 130,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildAnimatedItem(cat0, 35),
            buildAnimatedItem(cat1, 18),
            // Círculo central fijo (General)
            Transform.translate(
              offset: const Offset(0, 2),
              child: CategoryCircleAtom(
                label: 'General',
                icon: Icons.public,
                isGeneral: true,
                isSelected: state.selectedCategory == 'General',
                onTap: () => controller.selectCategory('General'),
              ),
            ),
            buildAnimatedItem(cat2, 18),
            buildAnimatedItem(cat3, 35),
          ],
        ),
      ),
    );
  }
}
