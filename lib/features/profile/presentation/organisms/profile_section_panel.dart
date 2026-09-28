import 'package:flutter/material.dart';

import '../atoms/profile_section_tab.dart';
import '../profile_colors.dart';

class ProfileSectionPanel extends StatelessWidget {
  const ProfileSectionPanel({
    super.key,
    required this.section,
    required this.onSectionSelected,
    required this.child,
  });

  final int section;
  final ValueChanged<int> onSectionSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 28.0;
        const gap = 22.0;
        final tabWidth =
            (constraints.maxWidth - 2 * horizontalPadding - 2 * gap) / 3;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: section.toDouble()),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (context, position, _) => Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _YellowPanelClipper(
                  tabCenter:
                      horizontalPadding +
                      tabWidth / 2 +
                      position * (tabWidth + gap),
                ),
                child: ColoredBox(
                  color: profileYellow,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 55),
                    child: child,
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 18,
                child: Row(
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      if (index > 0) const SizedBox(width: gap),
                      Expanded(
                        child: ProfileSectionTab(
                          label: const ['Favoritos', 'Amigos', 'Perfil'][index],
                          selected: section == index,
                          onTap: () => onSectionSelected(index),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _YellowPanelClipper extends CustomClipper<Path> {
  const _YellowPanelClipper({required this.tabCenter});

  final double tabCenter;

  @override
  Path getClip(Size size) {
    final left = (tabCenter - 61).clamp(0.0, size.width - 122);
    final right = left + 122;
    final panel = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(0, 55, size.width, size.height),
          topLeft: const Radius.circular(40),
          topRight: const Radius.circular(40),
          bottomLeft: const Radius.circular(0),
          bottomRight: const Radius.circular(0),
        ),
      );
    final tab = Path()
      ..moveTo((left - 22).clamp(0.0, size.width), 55)
      ..cubicTo(left - 4, 55, left + 3, 47, left + 7, 30)
      ..cubicTo(left + 11, 13, left + 22, 8, left + 38, 8)
      ..lineTo(right - 38, 8)
      ..cubicTo(right - 22, 8, right - 11, 13, right - 7, 30)
      ..cubicTo(
        right - 3,
        47,
        right + 4,
        55,
        (right + 22).clamp(0.0, size.width),
        55,
      )
      // Overlap below the rounded corners so the union has no seams.
      ..lineTo((right + 22).clamp(0.0, size.width), 95)
      ..lineTo((left - 22).clamp(0.0, size.width), 95)
      ..close();
    return Path.combine(PathOperation.union, panel, tab);
  }

  @override
  bool shouldReclip(_YellowPanelClipper oldClipper) =>
      oldClipper.tabCenter != tabCenter;
}
