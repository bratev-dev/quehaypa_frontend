import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/event_creation/presentation/controllers/event_creation_controller.dart';
import 'package:frontend/features/event_creation/presentation/organisms/event_creation_progress.dart';

void main() {
  testWidgets('los pasos siguen el arco y la mano acompaña el paso activo', (
    tester,
  ) async {
    Future<void> showStep(EventCreationStep step) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: EventCreationProgress(step: step, onPrevious: () {}),
            ),
          ),
        ),
      ),
    );

    await showStep(EventCreationStep.data);
    await tester.pumpAndSettle();
    final dataIcon = tester.getCenter(
      find.byIcon(Icons.event_available_outlined),
    );
    final detailsIcon = tester.getCenter(find.byIcon(Icons.image_outlined));
    final publishIcon = tester.getCenter(find.byIcon(Icons.send_rounded));
    final firstHand = tester.getTopLeft(find.byType(SvgPicture));

    expect(detailsIcon.dy, lessThan(dataIcon.dy));
    expect(publishIcon.dy, greaterThan(detailsIcon.dy));
    expect(firstHand.dx, lessThan(dataIcon.dx));
    expect(firstHand.dy, lessThan(dataIcon.dy));

    await showStep(EventCreationStep.details);
    await tester.pumpAndSettle();
    final secondHand = tester.getTopLeft(find.byType(SvgPicture));
    expect(secondHand.dx, greaterThan(firstHand.dx));

    await showStep(EventCreationStep.publish);
    await tester.pumpAndSettle();
    final thirdHand = tester.getTopLeft(find.byType(SvgPicture));
    expect(thirdHand.dx, greaterThan(secondHand.dx));
    expect(tester.takeException(), isNull);
  });
}
