import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../interests_colors.dart';

class InterestsTemplate extends StatelessWidget {
  const InterestsTemplate({super.key, required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: interestsYellow,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 402),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      top: 16,
                      left: constraints.maxWidth.clamp(0.0, 402.0) / 2 - 283,
                      width: 566,
                      height: 566,
                      child: SvgPicture.asset(
                        'assets/images/interests_background.svg',
                        width: 566,
                        height: 566,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 38, 18, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 368 / 283,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SvgPicture.asset(
                                'assets/images/Intereses.svg',
                                width: 368,
                                height: 283,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          content,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
