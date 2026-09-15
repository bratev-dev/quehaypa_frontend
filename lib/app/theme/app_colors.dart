import 'package:flutter/material.dart';

/// Paleta institucional de "Qué Hay Pa'?" y las reglas de color que dependen
/// del fondo de cada pantalla.
///
/// Por ahora centraliza el color del borde de los inputs en foco. El resto de
/// la app todavía tiene los hexadecimales repartidos en cada widget.
class AppColors {
  const AppColors._();

  /// Amarillo institucional. Fondo del login y de "Detalles personales".
  static const Color yellow = Color(0xFFFFD600);

  /// Azul institucional. Es el mismo del botón "Continuar".
  static const Color blue = Color(0xFF0038FF);

  /// Azul de fondo de la pantalla de registro (paso de credenciales).
  static const Color deepBlue = Color(0xFF0A47ED);

  // --- Borde de los inputs al recibir el foco ------------------------------
  // La regla es que el borde contraste con el fondo de su pantalla.
  // Para cambiar de idea en el futuro basta con editar estas dos constantes.

  /// Borde del input en foco sobre pantallas de fondo AMARILLO
  /// (login y "Detalles personales").
  static const Color inputFocusOnYellow = blue;

  /// Borde del input en foco sobre pantallas de fondo AZUL
  /// (registro: correo y contraseña).
  static const Color inputFocusOnBlue = yellow;
}
