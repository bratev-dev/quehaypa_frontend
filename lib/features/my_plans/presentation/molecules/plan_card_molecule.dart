import 'package:flutter/material.dart';

import '../atoms/plan_card_image_atom.dart';

class PlanCardMolecule extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback onViewMore; // Funcionalidad para el botón "Ver más"
  final bool isAddCard;

  const PlanCardMolecule({
    super.key,
    required this.title,
    required this.onTap,
    required this.onViewMore,
    this.isAddCard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isAddCard) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add, size: 36, color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(
        6,
      ), // Reducido de 8 a 6 para ganar espacio vital
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlanCardImageAtom(),
          const SizedBox(height: 4), // Reducido de 6 a 4
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
                // Botón "Ver más"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ), // Padding más compacto
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ver más',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
