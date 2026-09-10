import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginHeroHeader extends StatelessWidget {
  const LoginHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Círculo amarillo oscuro (#FFBB00)
        Positioned(
          top: size.height * 0.02,
          right: size.width * 0.05,
          width: size.width * 1.2,
          height: size.width * 1.2,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFBB00),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Ilustración SVG
        Positioned(
          top: size.height * 0.01,
          left: 0,
          width: size.width * 0.88,
          child: SvgPicture.asset(
            'assets/images/LoginImage.svg',
            fit: BoxFit.fitWidth,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}