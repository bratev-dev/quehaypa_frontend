import 'package:flutter/material.dart';

class OrganizerEventSkeleton extends StatelessWidget {
  const OrganizerEventSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 188,
    height: 171,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 103,
          decoration: BoxDecoration(
            color: const Color(0xFFE9E6E6),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 9),
        Container(width: 120, height: 10, color: const Color(0xFFE9E6E6)),
        const SizedBox(height: 9),
        Container(width: 70, height: 10, color: const Color(0xFFE9E6E6)),
      ],
    ),
  );
}
