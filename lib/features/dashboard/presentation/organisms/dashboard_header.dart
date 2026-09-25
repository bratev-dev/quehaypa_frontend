import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../molecules/rotating_categories_carousel.dart';
import 'blue_curve_header_painter.dart';
import 'header_arc_geometry.dart';

/// Header del dashboard. Al hacer scroll, el arco azul se aplana y sube hasta
/// quedar como una franja fija en el borde superior de la pantalla (cubriendo
/// la zona del notch) mientras el título se desvanece detrás de ella.
///
/// Todo se deriva de un único progreso `p` (0 = arco completo, 1 = franja
/// fija) proporcional al scroll, así que la animación es reversible y el alto
/// dibujado coincide exactamente con el que reserva el sliver en cada momento.
class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// Alto de la zona superior del sistema (notch / barra de estado), es decir
  /// `MediaQuery.padding.top`.
  final double topInset;

  const DashboardHeaderDelegate({required this.topInset});

  static const double _topPadding = 8;
  static const double _logoHeight = 100;
  static const double _logoToArcGap = 12;
  static const double _arcSagitta = 56;
  static const double _arcThickness = 115;
  static const double _bottomMargin = 45;

  /// Cuánto sube el título (en px, al final del recorrido) mientras se
  /// desvanece, además de quedar tapado por la franja.
  static const double _logoRise = 40;

  /// Fracción del recorrido tras la cual el título ya es totalmente
  /// transparente.
  static const double _logoFadeEnd = 0.7;

  /// Y del borde exterior del arco en los costados cuando el header está
  /// completamente expandido.
  double get _expandedOuterEdgeY =>
      topInset + _topPadding + _logoHeight + _logoToArcGap + _arcSagitta;

  @override
  double get maxExtent => _expandedOuterEdgeY + _arcThickness + _bottomMargin;

  // Colapsado: solo la franja, con el notch incluido y sin margen inferior.
  @override
  double get minExtent => topInset + _arcThickness;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoTop = topInset + _topPadding;

    final range = maxExtent - minExtent;
    final progress = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 0.0;
    final remaining = 1.0 - progress;

    final geometry = HeaderArcGeometry(
      width: screenWidth,
      outerEdgeY: _expandedOuterEdgeY * remaining,
      outerSagitta: _arcSagitta * remaining,
      thickness: _arcThickness + topInset * progress,
      topInset: topInset * progress,
    );

    // Misma fórmula que usa el sliver para el alto que reserva. Calcularlo
    // como bottomAtSides + margen da lo mismo salvo por redondeo de punto
    // flotante, y esa diferencia basta para que Flutter falle con
    // "layoutExtent exceeds paintExtent".
    final headerHeight = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    return ClipPath(
      clipper: _HeaderClipper(geometry),
      child: SizedBox(
        width: screenWidth,
        height: headerHeight,
        child: Container(
          color: const Color(0xFFFFD600),
          child: Stack(
            children: [
              // El título va ANTES que la franja para que el azul lo cubra
              // al subir, en vez de pintarse encima de ella.
              Positioned(
                top: logoTop - _logoRise * progress,
                left: 0,
                right: 0,
                height: _logoHeight,
                child: Opacity(
                  opacity: (1.0 - progress / _logoFadeEnd).clamp(0.0, 1.0),
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
                child: CustomPaint(painter: BlueCurveHeaderPainter(geometry)),
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
  bool shouldRebuild(covariant DashboardHeaderDelegate oldDelegate) =>
      oldDelegate.topInset != topInset;
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
