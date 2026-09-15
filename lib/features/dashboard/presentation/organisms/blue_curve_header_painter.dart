import 'package:flutter/material.dart';

class BlueCurveHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A47ED)
      ..style = PaintingStyle.fill;

    final path = Path();

    // 1. Borde superior del arco azul (el pico sube)
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.2, // Altura del arco superior
      size.width,
      size.height * 0.35,
    );

    // 2. Bajamos por la derecha para darle un grosor considerable a la franja
    path.lineTo(size.width, size.height * 0.95);

    // 3. Borde inferior paralelo (sigue la misma curva pero más abajo)
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.4, // Curva inferior paralela que le da gran grosor
      0,
      size.height * 0.95,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
