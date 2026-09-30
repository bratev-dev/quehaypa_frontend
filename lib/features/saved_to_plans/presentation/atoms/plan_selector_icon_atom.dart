import 'package:flutter/material.dart';

class PlanSelectorIconAtom extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const PlanSelectorIconAtom({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD600), // Amarillo característico
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Icon(
                  isSelected ? Icons.check : Icons.add,
                  color: isSelected ? Colors.black : Colors.black87,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
