import 'package:flutter/material.dart';

import '../event_creation_colors.dart';

class EventCreationNotch extends StatelessWidget {
  const EventCreationNotch({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(
    size: Size(69, 28),
    painter: _EventCreationNotchPainter(),
  );
}

class _EventCreationNotchPainter extends CustomPainter {
  const _EventCreationNotchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * .24,
        size.height,
        size.width * .43,
        size.height * .58,
        size.width * .5,
        0,
      )
      ..cubicTo(
        size.width * .57,
        size.height * .58,
        size.width * .76,
        size.height,
        size.width,
        size.height,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = EventCreationColors.blue);
  }

  @override
  bool shouldRepaint(covariant _EventCreationNotchPainter oldDelegate) => false;
}
