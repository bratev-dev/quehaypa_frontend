import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/atoms/interest_chip.dart';
import 'package:frontend/features/preferences/presentation/interest_catalog_fallback.dart';
import 'package:frontend/features/preferences/presentation/organisms/interest_options.dart';
import 'package:frontend/features/preferences/presentation/templates/interests_template.dart';

void main() {
  for (final size in const [
    Size(360, 740),
    Size(393, 852),
    Size(440, 859),
    Size(740, 360),
  ]) {
    testWidgets('selección y acción accesibles en $size con texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = <String>{};
      var saves = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => InterestsTemplate(
                  content: Column(
                    children: [
                      InterestOptions(
                        catalog: fallbackInterests,
                        selected: selected,
                        onToggle: (interest) => setState(() {
                          if (!selected.add(interest)) {
                            selected.remove(interest);
                          }
                        }),
                      ),
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed: () => saves++,
                        child: const Text('Guardar intereses'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Tecnología'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tecnología'));
      await tester.pump();
      expect(selected, contains('Tecnología'));
      expect(
        tester.widget<InterestChip>(find.byType(InterestChip).first).isSelected,
        isTrue,
      );

      await tester.ensureVisible(find.text('Guardar intereses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar intereses'));
      await tester.pump();
      expect(saves, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
