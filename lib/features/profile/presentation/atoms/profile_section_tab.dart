import 'package:flutter/material.dart';

import '../profile_colors.dart';

class ProfileSectionTab extends StatelessWidget {
  const ProfileSectionTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 29,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: profileBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    ),
  );
}
