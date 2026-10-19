import 'package:flutter/material.dart';

import '../event_creation_colors.dart';

class EventCreationButton extends StatelessWidget {
  const EventCreationButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 53,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary
            ? const Color(0xFFDBE0ED)
            : EventCreationColors.yellow,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
