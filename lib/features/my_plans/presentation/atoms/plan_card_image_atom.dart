import 'package:flutter/material.dart';

class PlanCardImageAtom extends StatelessWidget {
  final bool isAddButton;

  const PlanCardImageAtom({super.key, this.isAddButton = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isAddButton
          ? const Center(child: Icon(Icons.add, size: 36, color: Colors.white))
          : null,
    );
  }
}
