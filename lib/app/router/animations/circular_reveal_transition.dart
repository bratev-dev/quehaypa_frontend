import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircularRevealClipper extends CustomClipper<Path> {
  final double progress;
  final Alignment alignment;

  CircularRevealClipper({required this.progress, required this.alignment});

  @override
  Path getClip(Size size) {
    final double x = size.width * (alignment.x + 1) / 2;
    final double y = size.height * (alignment.y + 1) / 2;

    final double maxRadius = _getMaxRadius(size, x, y);
    final double radius = maxRadius * progress;

    return Path()
      ..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));
  }

  double _getMaxRadius(Size size, double x, double y) {
    final double w = size.width;
    final double h = size.height;

    final double d1 = (x * x + y * y);
    final double d2 = ((w - x) * (w - x) + y * y);
    final double d3 = (x * x + (h - y) * (h - y));
    final double d4 = ((w - x) * (w - x) + (h - y) * (h - y));

    return [d1, d2, d3, d4].map(math.sqrt).reduce(math.max);
  }

  @override
  bool shouldReclip(covariant CircularRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.alignment != alignment;
  }
}
