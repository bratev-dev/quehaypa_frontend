import 'package:flutter/material.dart';

import '../../../preferences/presentation/interests_colors.dart';

class InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 37),
        child: Material(
          color: isSelected ? interestsSelected : Colors.white,
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected ? interestsBlue : Colors.transparent,
              width: 3,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: interestsBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
