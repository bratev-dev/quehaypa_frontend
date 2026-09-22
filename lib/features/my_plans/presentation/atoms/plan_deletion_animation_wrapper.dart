import 'package:flutter/material.dart';

class PlanDeletionAnimationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const PlanDeletionAnimationWrapper({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  // Método estático para poder llamarlo fácilmente desde afuera si lo deseas
  static State<PlanDeletionAnimationWrapper> of(BuildContext context) {
    return context
        .findAncestorStateOfType<_PlanDeletionAnimationWrapperState>()!;
  }

  @override
  State<PlanDeletionAnimationWrapper> createState() =>
      _PlanDeletionAnimationWrapperState();
}

class _PlanDeletionAnimationWrapperState
    extends State<PlanDeletionAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(
      milliseconds: 350,
    ), // Súper rápido y fluido (< 0.5s)
    vsync: this,
  );

  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutBack,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  // Función pública para activar la animación hacia arriba/la caneca
  void playDeleteAnimation() {
    _controller.forward().then((_) {
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.0).animate(_scaleAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
        child: widget.child,
      ),
    );
  }
}
