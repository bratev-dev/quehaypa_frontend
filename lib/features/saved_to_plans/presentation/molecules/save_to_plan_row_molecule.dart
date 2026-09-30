import 'package:flutter/material.dart';

import '../atoms/plan_selector_icon_atom.dart';

class SaveToPlanRowMolecule extends StatelessWidget {
  final String planName;
  final String details;
  final bool isSelected;
  final VoidCallback onToggle;
  final bool isSaving;

  const SaveToPlanRowMolecule({
    super.key,
    required this.planName,
    required this.details,
    required this.isSelected,
    required this.onToggle,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63), // Fucsia/Rosa característico
        borderRadius: BorderRadius.circular(30), // Forma de pastilla alargada
      ),
      child: Row(
        children: [
          // Miniatura blanca izquierda
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          // Textos (Nombre del plan y detalles)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Botón selector derecho
          PlanSelectorIconAtom(
            isSelected: isSelected,
            onTap: onToggle,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}
