import 'package:flutter/material.dart';

class PlanActionIconAtom extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const PlanActionIconAtom({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, // Más grandes y cuadrados
        height: 64, // Más grandes y cuadrados
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black87,
          size: 28, // Icono proporcionalmente más grande
        ),
      ),
    );
  }
}
