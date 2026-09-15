import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../molecules/rotating_categories_carousel.dart';
import 'blue_curve_header_painter.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ClipPath(
      // Recorta TODO el header siguiendo la forma exterior
      // de la sección azul inferior.
      clipper: _HeaderClipper(),
      child: Container(
        color: const Color(0xFFFFD600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 45),

            // LOGO
            SizedBox(
              height: 125,
              child: SvgPicture.asset(
                'assets/images/Que_Hay_Pa_title.svg',
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const Text(
                  '¿Qué Hay Pa?',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // SECCIÓN AZUL
            SizedBox(
              width: screenWidth,
              height: 205,
              child: CustomPaint(
                painter: BlueCurveHeaderPainter(),
                child: const Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 30,
                    bottom: 15,
                  ),
                  child: RotatingCategoriesCarousel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Comenzamos arriba a la izquierda.
    path.moveTo(0, 0);

    // Parte superior completa.
    path.lineTo(size.width, 0);

    // Bajamos por el lado derecho.
    path.lineTo(size.width, size.height - 45);

    // Arco inferior.
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height - 105,
      0,
      size.height - 45,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
