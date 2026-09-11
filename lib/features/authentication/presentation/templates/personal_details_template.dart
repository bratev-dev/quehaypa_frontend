import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PersonalDetailsTemplate extends StatelessWidget {
  final Widget formContent;
  final String svgAssetPath;

  // Nuevos parámetros para ajustar el tamaño y posición del SVG
  final double svgTopFactor;
  final double svgRightPosition;
  final double svgWidthFactor;

  const PersonalDetailsTemplate({
    super.key,
    required this.formContent,
    required this.svgAssetPath,
    this.svgTopFactor = 0.01, // Valor por defecto
    this.svgRightPosition = 0.0, // Valor por defecto
    this.svgWidthFactor = 0.88, // Valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFD600), // Fondo general amarillo
      body: Stack(
        children: [
          // Círculo de fondo amarillo más oscuro
          Positioned(
            top: size.height * 0.02,
            right: -size.width * 0.15,
            width: size.width * 1.4,
            height: size.width * 1.4,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(255, 189, 2, 1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Ilustración SVG superior posicionada dinámicamente
          Positioned(
            top: size.height * svgTopFactor, // <-- Usa el parámetro
            right: svgRightPosition, // <-- Usa el parámetro
            width: size.width * svgWidthFactor, // <-- Usa el parámetro
            child: SvgPicture.asset(
              svgAssetPath,
              fit: BoxFit.fitWidth,
              alignment: Alignment.centerRight,
            ),
          ),

          // Contenido inferior flotante
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 40.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.38),
                    formContent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
