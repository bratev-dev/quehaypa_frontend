import 'package:flutter/material.dart';

import 'header_arc_geometry.dart';

/// Pinta la franja azul del header como un anillo entre dos arcos de círculo
/// concéntricos ([HeaderArcGeometry]), así que su grosor es constante en
/// todo el arco.
class BlueCurveHeaderPainter extends CustomPainter {
  final HeaderArcGeometry geometry;

  const BlueCurveHeaderPainter(this.geometry);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A47ED)
      ..style = PaintingStyle.fill;

    canvas.drawPath(geometry.ringPath(), paint);
  }

  @override
  bool shouldRepaint(covariant BlueCurveHeaderPainter oldDelegate) =>
      oldDelegate.geometry.width != geometry.width ||
      oldDelegate.geometry.outerEdgeY != geometry.outerEdgeY ||
      oldDelegate.geometry.outerSagitta != geometry.outerSagitta ||
      oldDelegate.geometry.thickness != geometry.thickness;
}
