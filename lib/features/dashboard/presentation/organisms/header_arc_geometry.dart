import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometría del arco azul de categorías del dashboard: dos arcos con el
/// **mismo radio**, donde el interior es el exterior desplazado [thickness]
/// hacia abajo.
///
/// Se probó antes con círculos **concéntricos** (mismo centro, distinto
/// radio). Eso da distancia perpendicular constante — geométricamente son
/// curvas paralelas — pero el ojo lee el alto *vertical* de la franja, y ese
/// no es constante: el círculo interior, al tener menos radio, debe curvarse
/// más para cruzar el mismo ancho de pantalla, así que sus puntas caen más
/// abajo y la franja se ve ~25 % más alta en los extremos que en el centro
/// (efecto de óvalo).
///
/// Con el mismo radio y desplazamiento vertical, ambos bordes tienen
/// idéntica curvatura y la franja mide exactamente [thickness] de alto en
/// todo el arco.
///
/// Todas las coordenadas están en el sistema del header completo (Y=0 en la
/// parte superior del header, no de la sección azul).
class HeaderArcGeometry {
  /// Ancho de la pantalla / del header.
  final double width;

  /// Y donde el borde exterior (superior) del arco toca los costados.
  /// Ojo: en el centro el arco sube [outerSagitta] por encima de este valor.
  final double outerEdgeY;

  /// Cuánto sube el arco en el centro respecto a los costados (la "flecha"
  /// o sagitta del arco exterior).
  final double outerSagitta;

  /// Grosor de la franja azul, constante en todo el arco.
  final double thickness;

  const HeaderArcGeometry({
    required this.width,
    required this.outerEdgeY,
    required this.outerSagitta,
    required this.thickness,
  });

  double get halfChord => width / 2;

  /// Radio de ambos arcos, a partir de la cuerda (2 * [halfChord]) y la
  /// flecha ([outerSagitta]): R = (a² + s²) / (2s).
  double get radius =>
      (halfChord * halfChord + outerSagitta * outerSagitta) /
      (2 * outerSagitta);

  /// Centro del arco exterior (superior).
  Offset get outerCenter =>
      Offset(width / 2, outerEdgeY - outerSagitta + radius);

  /// Centro del arco interior: el mismo, desplazado [thickness] hacia abajo.
  Offset get innerCenter => Offset(outerCenter.dx, outerCenter.dy + thickness);

  /// Medio ángulo que abarca el arco. Es el mismo para ambos bordes, porque
  /// comparten radio.
  double get _halfAngle => math.asin((halfChord / radius).clamp(-1.0, 1.0));

  /// Y del borde interior (inferior) del arco en los costados de la pantalla.
  double get bottomAtSides => outerEdgeY + thickness;

  /// Y de la línea media de la franja en una coordenada X dada. Sirve para
  /// ubicar contenido (como los círculos de categoría) centrado sobre el arco.
  double centerlineY(double x) {
    final dx = (x - outerCenter.dx).clamp(-radius, radius);
    final outerY = outerCenter.dy - math.sqrt(radius * radius - dx * dx);
    return outerY + thickness / 2;
  }

  /// La franja completa: región entre el arco exterior y el interior.
  /// Se dibuja el arco exterior (izquierda → derecha, pasando por arriba),
  /// baja por el costado derecho, el arco interior (derecha → izquierda,
  /// mismo radio pero centro desplazado) y cierra por el costado izquierdo.
  Path ringPath() {
    final halfAngle = _halfAngle;

    return Path()
      ..addArc(
        Rect.fromCircle(center: outerCenter, radius: radius),
        -math.pi / 2 - halfAngle,
        2 * halfAngle,
      )
      ..arcTo(
        Rect.fromCircle(center: innerCenter, radius: radius),
        -math.pi / 2 + halfAngle,
        -2 * halfAngle,
        false,
      )
      ..close();
  }

  /// Solo el borde interior, como el contorno completo del header (usado
  /// por el clipper): rectángulo amarillo arriba + arco azul abajo.
  Path innerArcPath() {
    final halfAngle = _halfAngle;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, bottomAtSides)
      ..arcTo(
        Rect.fromCircle(center: innerCenter, radius: radius),
        -math.pi / 2 + halfAngle,
        -2 * halfAngle,
        false,
      )
      ..close();
  }
}
