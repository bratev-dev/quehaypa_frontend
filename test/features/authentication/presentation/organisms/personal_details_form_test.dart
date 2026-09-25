import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/authentication/presentation/organisms/personal_details_form.dart';

import '../../../../helpers/widget_finders.dart';

/// Validaciones del paso "datos personales" del registro (HU-1.1).
void main() {
  late ProviderContainer container;

  Future<void> pumpForm(
    WidgetTester tester, {
    UserRole role = UserRole.user,
  }) async {
    useTallScreen(tester);
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(registerControllerProvider.notifier).selectRole(role);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PersonalDetailsForm()),
          ),
        ),
      ),
    );
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Ana',
    String lastName = 'Ruiz',
    String username = 'ana.ruiz',
    String day = '15',
    String month = '02',
    String year = '1998',
  }) async {
    await tester.enterText(fieldWithHint('Nombre'), name);
    await tester.enterText(fieldWithHint('Apellido'), lastName);
    await tester.enterText(fieldWithHint('Nombre de usuario'), username);
    await tester.enterText(fieldWithHint('DD'), day);
    await tester.enterText(fieldWithHint('MM'), month);
    await tester.enterText(fieldWithHint('AAAA'), year);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Continuar'));
    await tester.pump();
  }

  RegisterState state() => container.read(registerControllerProvider);

  testWidgets('con campos vacíos pide completarlos', (tester) async {
    await pumpForm(tester);

    await submit(tester);

    expect(find.text('Por favor completa todos los campos.'), findsOneWidget);
    expect(state().currentStep, RegisterStep.personalDetails);
  });

  testWidgets('el campo CC solo aparece para organizadores', (tester) async {
    await pumpForm(tester);
    expect(fieldWithHint('CC'), findsNothing);
  });

  testWidgets('organizador sin cédula no avanza', (tester) async {
    await pumpForm(tester, role: UserRole.organizer);
    expect(fieldWithHint('CC'), findsOneWidget);

    await fill(tester);
    await submit(tester);

    expect(find.text('Por favor ingresa tu número de cédula.'), findsOneWidget);
  });

  final fechasInvalidas = <String, (String, String, String, String)>{
    'día fuera de rango': (
      '32',
      '01',
      '2000',
      'El día debe estar entre 1 y 31.',
    ),
    'mes no numérico': ('10', 'ab', '2000', 'El mes debe ser un número.'),
    'año anterior a 1900': (
      '10',
      '10',
      '1850',
      'El año debe estar entre 1900 y ${DateTime.now().year}.',
    ),
    'fecha inexistente (31 de febrero)': (
      '31',
      '02',
      '2000',
      'La fecha de nacimiento no es válida.',
    ),
  };

  fechasInvalidas.forEach((caso, datos) {
    testWidgets('rechaza $caso', (tester) async {
      await pumpForm(tester);
      await fill(tester, day: datos.$1, month: datos.$2, year: datos.$3);

      await submit(tester);

      expect(find.text(datos.$4), findsOneWidget);
      expect(state().name, isEmpty);
    });
  });

  testWidgets('rechaza una fecha futura', (tester) async {
    final manana = DateTime.now().add(const Duration(days: 1));
    // El 31 de diciembre "mañana" ya cae en un año fuera de rango.
    final esperado = manana.year == DateTime.now().year
        ? 'La fecha de nacimiento no puede ser una fecha futura.'
        : 'El año debe estar entre 1900 y ${DateTime.now().year}.';
    await pumpForm(tester);
    await fill(
      tester,
      day: '${manana.day}',
      month: '${manana.month}',
      year: '${manana.year}',
    );

    await submit(tester);

    expect(find.text(esperado), findsOneWidget);
  });

  testWidgets('con datos válidos guarda y pasa a intereses', (tester) async {
    await pumpForm(tester);
    await fill(tester, name: ' Ana ');

    await submit(tester);

    expect(state().name, 'Ana');
    expect(state().birthDate, '15/02/1998');
    expect(state().currentStep, RegisterStep.interests);
  });

  group('aviso al salir de un campo de fecha', () {
    testWidgets('avisa de inmediato un día imposible', (tester) async {
      await pumpForm(tester);

      await tester.enterText(fieldWithHint('DD'), '40');
      await tester.tap(fieldWithHint('MM'));
      await tester.pump();

      expect(find.text('El día debe estar entre 1 y 31.'), findsOneWidget);
    });

    testWidgets('con los tres campos revisa la fecha completa', (tester) async {
      await pumpForm(tester);

      await tester.enterText(fieldWithHint('DD'), '31');
      await tester.enterText(fieldWithHint('MM'), '04');
      await tester.enterText(fieldWithHint('AAAA'), '2001');
      await tester.tap(fieldWithHint('Nombre'));
      await tester.pump();

      expect(find.text('La fecha de nacimiento no es válida.'), findsOneWidget);
    });

    testWidgets('un campo vacío no reclama todavía', (tester) async {
      await pumpForm(tester);

      await tester.tap(fieldWithHint('DD'));
      await tester.tap(fieldWithHint('MM'));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
