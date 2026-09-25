import 'package:flutter/material.dart';

class CategoryCircleAtom extends StatelessWidget {
  /// Diámetro del círculo cuando la categoría está enfocada (en el centro).
  static const double focusedSize = 68;

  /// Diámetro del círculo cuando la categoría no está enfocada.
  static const double normalSize = 52;

  final String label;
  final IconData icon;

  /// La categoría está en el centro de la ruleta: crece y lleva el anillo.
  final bool isFocused;

  /// La categoría es la elegida en el estado; solo afecta el peso del texto.
  final bool isSelected;

  /// Solo cambia el color del ícono, para distinguir "General".
  final bool isGeneral;
  final VoidCallback onTap;

  const CategoryCircleAtom({
    super.key,
    required this.label,
    required this.icon,
    this.isFocused = false,
    this.isSelected = false,
    this.isGeneral = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caja de tamaño fijo: el círculo se escala dentro de ella, así la
          // etiqueta de abajo no se mueve cuando una categoría crece.
          SizedBox(
            width: focusedSize,
            height: focusedSize,
            child: AnimatedScale(
              scale: isFocused ? 1.0 : normalSize / focusedSize,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: isFocused
                      ? Border.all(color: const Color(0xFFFFD600), width: 3.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isGeneral ? const Color(0xFF0A47ED) : Colors.black87,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Texto del interés debajo del círculo
          SizedBox(
            width: 65,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
