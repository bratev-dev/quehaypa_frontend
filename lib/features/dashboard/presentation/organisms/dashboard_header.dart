import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../molecules/rotating_categories_carousel.dart';
import 'blue_curve_header_painter.dart';
import 'header_arc_geometry.dart';

class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DashboardHeaderDelegate();

  static const double _topPadding = 8;
  static const double _logoHeight = 100;
  static const double _logoToArcGap = 12;
  static const double _arcSagitta = 56;
  static const double _arcThickness = 115;
  static const double _bottomMargin = 45; // Tu regla de oro intacta

  @override
  double get maxExtent {
    final topMargin = 24.0 + _topPadding; // Margen superior seguro estándar
    final arcTopAtCenter = topMargin + _logoHeight + _logoToArcGap;
    final outerEdgeY = arcTopAtCenter + _arcSagitta;
    final dummyGeometry = HeaderArcGeometry(
      width: 400,
      outerEdgeY: outerEdgeY,
      outerSagitta: _arcSagitta,
      thickness: _arcThickness,
    );
    return dummyGeometry.bottomAtSides + _bottomMargin;
  }

  @override
  double get minExtent {
    final topMargin = 24.0 + _topPadding;
    final arcTopAtCenter = topMargin + _logoHeight + _logoToArcGap;
    final dummyGeometry = HeaderArcGeometry(
      width: 400,
      outerEdgeY: arcTopAtCenter,
      outerSagitta: 0,
      thickness: _arcThickness,
    );
    return dummyGeometry.bottomAtSides + _bottomMargin;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topMargin = MediaQuery.of(context).padding.top + _topPadding;

    // Calculamos el progreso del scroll basado estrictamente en el tamaño de tu header
    final range = maxExtent - minExtent;
    final scrollProgress = range > 0
        ? (shrinkOffset / range).clamp(0.0, 1.0)
        : 0.0;

    // La sagitta de tu diseño original pasa suavemente de 56 a 0 (línea recta)
    final dynamicSagitta = _arcSagitta * (1.0 - scrollProgress);

    final arcTopAtCenter = topMargin + _logoHeight + _logoToArcGap;
    final outerEdgeY = arcTopAtCenter + dynamicSagitta;

    final geometry = HeaderArcGeometry(
      width: screenWidth,
      outerEdgeY: outerEdgeY,
      outerSagitta:
          dynamicSagitta, // Tu arco animado manteniendo tus proporciones
      thickness: _arcThickness,
    );

    final headerHeight = geometry.bottomAtSides + _bottomMargin;

    return ClipPath(
      clipper: _HeaderClipper(geometry),
      child: SizedBox(
        width: screenWidth,
        height: headerHeight,
        child: Container(
          color: const Color(0xFFFFD600),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: BlueCurveHeaderPainter(geometry)),
              ),

              // LOGO: Tu logo original desplazándose hacia arriba y desvaneciéndose al scrollear
              Positioned(
                top: topMargin - (shrinkOffset * 0.9),
                left: 0,
                right: 0,
                height: _logoHeight,
                child: Opacity(
                  opacity: (1.0 - (scrollProgress * 2.0)).clamp(0.0, 1.0),
                  child: SvgPicture.asset(
                    'assets/images/Que_Hay_Pa_title.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const Center(
                      child: Text(
                        '¿Qué Hay Pa?',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: RotatingCategoriesCarousel(geometry: geometry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardHeaderDelegate oldDelegate) => true;
}

class _HeaderClipper extends CustomClipper<Path> {
  final HeaderArcGeometry geometry;

  const _HeaderClipper(this.geometry);

  @override
  Path getClip(Size size) => geometry.innerArcPath();

  @override
  bool shouldReclip(covariant _HeaderClipper oldClipper) =>
      oldClipper.geometry.width != geometry.width ||
      oldClipper.geometry.outerEdgeY != geometry.outerEdgeY ||
      oldClipper.geometry.outerSagitta != geometry.outerSagitta ||
      oldClipper.geometry.thickness != geometry.thickness;
}
