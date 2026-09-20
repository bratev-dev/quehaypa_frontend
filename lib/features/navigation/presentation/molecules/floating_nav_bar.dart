import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_provider.dart';
import '../atoms/nav_icon_button.dart';

class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final icons = [
      Icons.home_rounded,
      Icons.map_rounded,
      Icons.event_note_rounded,
      Icons.person_rounded,
    ];

    return Container(
      height: 78,
      // Margen horizontal más grande para que la cápsula se acorte a lo ancho
      margin: const EdgeInsets.symmetric(horizontal: 55, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF7E22CE),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(icons.length, (index) {
          return NavIconButton(
            icon: icons[index],
            isSelected: currentIndex == index,
            onTap: () {
              ref.read(navigationIndexProvider.notifier).setIndex(index);
            },
          );
        }),
      ),
    );
  }
}
