import 'package:flutter/material.dart';

/// Muesca decorativa que conecta la fecha seleccionada con la agenda.
class CalendarSelectionNotch extends StatelessWidget {
  const CalendarSelectionNotch({super.key});

  static const double width = 45;
  static const double height = 23;

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: width,
    height: height,
    child: CustomPaint(painter: _CalendarSelectionNotchPainter()),
  );
}

class _CalendarSelectionNotchPainter extends CustomPainter {
  const _CalendarSelectionNotchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * .28,
        size.height,
        size.width * .38,
        size.height * .7,
        size.width * .5,
        0,
      )
      ..cubicTo(
        size.width * .62,
        size.height * .7,
        size.width * .72,
        size.height,
        size.width,
        size.height,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFCD413));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
