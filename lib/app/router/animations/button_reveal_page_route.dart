import 'package:flutter/material.dart';

/// Despliega la ruta desde el rectángulo del botón que la abrió.
class ButtonRevealPageRoute<T> extends PageRouteBuilder<T> {
  ButtonRevealPageRoute({required Rect origin, required WidgetBuilder builder})
    : super(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 680),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          return AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final curve = animation.status == AnimationStatus.reverse
                  ? Curves.easeInCubic
                  : Curves.easeInOutCubic;
              return ClipPath(
                clipper: _ButtonRevealClipper(
                  origin: origin,
                  progress: curve.transform(animation.value),
                ),
                child: child,
              );
            },
          );
        },
      );
}

class _ButtonRevealClipper extends CustomClipper<Path> {
  const _ButtonRevealClipper({required this.origin, required this.progress});

  final Rect origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final destination = Offset.zero & size;
    final rect = Rect.lerp(origin, destination, progress)!;
    final radius = Radius.circular(20 * (1 - progress));
    return Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
  }

  @override
  bool shouldReclip(covariant _ButtonRevealClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.progress != progress;
}
