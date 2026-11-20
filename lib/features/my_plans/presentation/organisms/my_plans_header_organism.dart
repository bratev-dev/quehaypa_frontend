import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyPlansHeaderOrganism extends StatelessWidget {
  const MyPlansHeaderOrganism({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 16;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: screenWidth * 0.75,
            height: 90,
            child: SvgPicture.asset(
              'assets/images/misPlanes.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Center(
                child: Text(
                  'MIS PLANES',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
