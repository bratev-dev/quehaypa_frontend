import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../atoms/nav_icon_button.dart';

class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key, this.organizer = false});
  final bool organizer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final icons = <IconData>[
      Icons.home_rounded, Icons.map_rounded,
      organizer ? Icons.calendar_month_rounded : Icons.event_note_rounded,
      Icons.person_rounded,
    ];
    return Container(
      height: 78,
      margin: EdgeInsets.symmetric(horizontal: organizer ? 28 : 55, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF7E22CE),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(icons.length, (index) => NavIconButton(
          icon: icons[index], compact: organizer, isSelected: currentIndex == index,
          onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(index),
        )),
      ),
    );
  }
}
