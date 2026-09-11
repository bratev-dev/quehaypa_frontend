import 'package:flutter/material.dart';

class RoleCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final double? widthFactor;
  final AlignmentGeometry alignment;

  const RoleCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.widthFactor,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 1.0,
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30), // Forma de píldora
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD600) : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
