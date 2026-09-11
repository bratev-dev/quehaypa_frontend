import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegisterHeroHeader extends StatelessWidget {
  const RegisterHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          top: size.height * 0.02,
          right: -size.width * 0.15,
          width: size.width * 1.2,
          height: size.width * 1.2,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF002BFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Ilustración SVG de Registro
        Positioned(
          top: size.height * 0.01,
          right: 0,
          width: size.width * 0.88,
          child: SvgPicture.asset(
            'assets/images/RegisterImage.svg',
            fit: BoxFit.fitWidth,
            alignment: Alignment.centerRight,
          ),
        ),
      ],
    );
  }
}
