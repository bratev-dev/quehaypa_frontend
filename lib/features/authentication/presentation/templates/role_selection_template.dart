import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RoleSelectionTemplate extends StatelessWidget {
  final Widget formContent;
  final String svgAssetPath;

  const RoleSelectionTemplate({
    super.key,
    required this.formContent,
    required this.svgAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Círculo de fondo azul
        Positioned(
          top: size.height * 0.02,
          right: -size.width * 0.37,
          width: size.width * 1.5,
          height: size.width * 1.5,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0032C2),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Ilustración SVG
        Positioned(
          top: size.height * 0.063,
          right: 0,
          width: size.width * 0.9,
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
                left: 32.0,
                right: 32.0,
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
    );
  }
}
