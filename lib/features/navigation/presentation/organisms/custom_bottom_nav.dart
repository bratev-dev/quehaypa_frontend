import 'package:flutter/material.dart';

import '../molecules/floating_nav_bar.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key, this.organizer = false});

  final bool organizer;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: SafeArea(child: FloatingNavBar(organizer: organizer)),
    );
  }
}
