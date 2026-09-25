import 'package:flutter/material.dart';

class NavIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const NavIconButton({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 78,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,

            width: isSelected ? 64 : 48,
            height: isSelected ? 64 : 48,

            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFC084FC)
                  : const Color.fromRGBO(255, 242, 253, 1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF7E22CE),
              size: isSelected ? 30 : 24,
            ),
          ),
        ),
      ),
    );
  }
}
