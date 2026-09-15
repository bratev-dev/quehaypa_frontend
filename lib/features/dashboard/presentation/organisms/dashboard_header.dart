import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../molecules/rotating_categories_carousel.dart';
import 'blue_curve_header_painter.dart';
import 'header_arc_geometry.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  // --- Parámetros ajustables del header ------------------------------------
  // Para reducir más el espacio amarillo: baja _logoHeight (el logo se
  // escala proporcionalmente, sin dejar espacio muerto) o _topPadding.
  // Para cambiar qué tan pronunciado se ve el arco azul: ajusta _arcSagitta
  // (cuánto sube en el centro). Para engrosar/adelgazar la franja azul:
  // ajusta _arcThickness. El resto (radio del arco, alto total del header,
  // posición de los círculos) se deriva de estos valores en
  // HeaderArcGeometry — no hay que recalcular nada a mano.
  static const double _topPadding = 8;
  static const double _logoHeight = 100;
  static const double _logoToArcGap = 12;
  static const double _arcSagitta = 56;
  static const double _arcThickness = 115;
  static const double _bottomMargin = 45;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topMargin = MediaQuery.of(context).padding.top + _topPadding;

    // El arco se posiciona por su CIMA (el punto más alto, en el centro),
    // no por los costados: en el centro el arco sube _arcSagitta por encima
    // de outerEdgeY, y es ahí donde puede chocar con el logo.
    final arcTopAtCenter = topMargin + _logoHeight + _logoToArcGap;
    final outerEdgeY = arcTopAtCenter + _arcSagitta;

    final geometry = HeaderArcGeometry(
      width: screenWidth,
      outerEdgeY: outerEdgeY,
      outerSagitta: _arcSagitta,
      thickness: _arcThickness,
    );

    final headerHeight = geometry.bottomAtSides + _bottomMargin;

    return ClipPath(
      // Recorta TODO el header siguiendo el borde interior del arco
      // (misma geometría que pinta la franja azul, así que calzan).
      clipper: _HeaderClipper(geometry),
      child: SizedBox(
        width: screenWidth,
        height: headerHeight,
        child: Container(
          color: const Color(0xFFFFD600),
          child: Stack(
            children: [
              // FRANJA AZUL: anillo entre el arco exterior y el interior.
              Positioned.fill(
                child: CustomPaint(painter: BlueCurveHeaderPainter(geometry)),
              ),

              // LOGO
              Positioned(
                top: topMargin,
                left: 0,
                right: 0,
                height: _logoHeight,
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

              // CATEGORÍAS, posicionadas sobre la línea media del arco.
              Positioned.fill(
                child: RotatingCategoriesCarousel(geometry: geometry),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
