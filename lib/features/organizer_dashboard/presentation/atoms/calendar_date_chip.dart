import 'package:flutter/material.dart';

class CalendarDateChip extends StatelessWidget {
  const CalendarDateChip({
    super.key,
    required this.topLabel,
    required this.bottomLabel,
    required this.selected,
    required this.onTap,
  });

  final String topLabel;
  final String bottomLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$topLabel $bottomLabel',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 46,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              topLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: selected ? 1 : 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              bottomLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
