import 'package:flutter/material.dart';

class PlanSelectorIconAtom extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const PlanSelectorIconAtom({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD600), // Amarillo característico
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isSelected ? Icons.check : Icons.add,
            color: isSelected ? Colors.black : Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }
}
