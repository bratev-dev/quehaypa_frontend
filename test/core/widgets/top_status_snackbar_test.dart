import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/top_status_snackbar.dart';

void main() {
  testWidgets(
    'muestra confirmación superior y la retira después de tres segundos',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => TopStatusSnackbar.show(
                  context,
                  message: 'Evento guardado',
                  success: true,
                ),
                child: const Text('Guardar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Guardar'));
      await tester.pump();

      expect(find.text('Evento guardado'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Evento guardado'), findsNothing);
    },
  );

  testWidgets('reemplaza el aviso anterior al mostrar uno nuevo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () =>
                      TopStatusSnackbar.show(context, message: 'Primer aviso'),
                  child: const Text('Primero'),
                ),
                TextButton(
                  onPressed: () => TopStatusSnackbar.show(
                    context,
                    message: 'Segundo aviso',
                    success: true,
                  ),
                  child: const Text('Segundo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Primero'));
    await tester.pump();
    expect(find.byIcon(Icons.info_rounded), findsOneWidget);

    await tester.tap(find.text('Segundo'));
    await tester.pump();
    expect(find.text('Primer aviso'), findsNothing);
    expect(find.text('Segundo aviso'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
