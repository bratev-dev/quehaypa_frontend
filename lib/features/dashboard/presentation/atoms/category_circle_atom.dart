import 'package:flutter/material.dart';

class CategoryCircleAtom extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isGeneral;
  final VoidCallback onTap;

  const CategoryCircleAtom({
    super.key,
    required this.label,
    required this.icon,
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
          Container(
            width: isGeneral ? 68 : 52,
            height: isGeneral ? 68 : 52,
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
              border: isSelected
                  ? Border.all(color: const Color(0xFFFFD600), width: 3.5)
                  : null,
            ),
            child: Icon(
              icon,
              color: isGeneral ? const Color(0xFF0A47ED) : Colors.black87,
              size: isGeneral ? 32 : 24,
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
