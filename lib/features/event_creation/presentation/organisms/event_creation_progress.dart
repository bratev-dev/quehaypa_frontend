import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/event_creation_controller.dart';
import '../event_creation_colors.dart';

class EventCreationProgress extends StatelessWidget {
  const EventCreationProgress({
    super.key,
    required this.step,
    required this.onPrevious,
  });

  final EventCreationStep step;
  final VoidCallback onPrevious;

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeInOutCubic;
  static const _verticalOffset = -6.0;
  static const _labels = ['DATOS', 'DETALLES', 'PUBLICAR'];
  static const _icons = [
    Icons.event_available_outlined,
    Icons.image_outlined,
    Icons.send_rounded,
  ];

  // Centros y alturas de los tres estados del indicador en Figma.
  static const _centers = [
    [100.0, 176.0, 247.0],
    [84.0, 177.0, 247.0],
    [84.0, 169.0, 269.0],
  ];
  static const _circleTops = [
    [40.0, 35.0, 47.0],
    [47.0, 33.0, 47.0],
    [51.0, 36.0, 44.0],
  ];
  static const _handTops = [7.0, 0.0, 11.0];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 125,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final horizontalScale = constraints.maxWidth / 340;
        final centers = _centers[step.index]
            .map((center) => center * horizontalScale)
            .toList();
        final circleTops = _circleTops[step.index];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < 3; index++)
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: centers[index] - 50,
                top: circleTops[index] - 26 + _verticalOffset,
                child: AnimatedOpacity(
                  duration: _duration,
                  opacity: index == step.index ? 0 : 1,
                  child: Semantics(
                    label: _labels[index],
                    child: CustomPaint(
                      size: const Size(100, 100),
                      painter: _CurvedStepLabelPainter(
                        label: _labels[index],
                        index: index,
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: _duration,
              curve: _curve,
              left: centers[step.index] - 49,
              top: _handTops[step.index] + _verticalOffset,
              child: SvgPicture.asset(
                'assets/images/Hand.svg',
                width: 71,
                height: 105,
              ),
            ),
            for (var index = 0; index < 3; index++)
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: centers[index] - 29,
                top: circleTops[index] + _verticalOffset,
                child: Semantics(
                  button: index == step.index - 1,
                  label: 'Paso ${index + 1}: ${_labels[index]}',
                  child: GestureDetector(
                    onTap: index == step.index - 1 ? onPrevious : null,
                    child: AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: index == step.index
                            ? Colors.white
                            : index < step.index
                            ? EventCreationColors.yellow
                            : const Color(0xFFDBE0ED),
                        shape: BoxShape.circle,
                        border: index == step.index
                            ? Border.all(
                                color: EventCreationColors.yellow,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        _icons[index],
                        color: index == step.index
                            ? EventCreationColors.yellow
                            : index < step.index
                            ? Colors.white
                            : EventCreationColors.muted,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CurvedStepLabelPainter extends CustomPainter {
  const _CurvedStepLabelPainter({required this.label, required this.index});

  final String label;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final start = switch (index) {
      0 => -155.0,
      1 => -125.0,
      _ => -92.0,
    };
    final end = switch (index) {
      0 => -105.0,
      1 => -55.0,
      _ => -20.0,
    };
    const radius = 43.0;
    final center = Offset(size.width / 2, 55);

    for (var letter = 0; letter < label.length; letter++) {
      final fraction = label.length == 1 ? .5 : letter / (label.length - 1);
      final angle = (start + (end - start) * fraction) * math.pi / 180;
      final painter = TextPainter(
        text: TextSpan(
          text: label[letter],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedStepLabelPainter oldDelegate) =>
      oldDelegate.label != label || oldDelegate.index != index;
}
