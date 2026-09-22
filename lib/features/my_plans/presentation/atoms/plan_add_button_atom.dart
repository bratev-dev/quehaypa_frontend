import 'package:flutter/material.dart';

class PlanAddButtonAtom extends StatelessWidget {
  final VoidCallback onTap;

  const PlanAddButtonAtom({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150, // Ajustado a la proporción de la tarjeta completa
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, size: 40, color: Colors.white),
        ),
      ),
    );
  }
}
