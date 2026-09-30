import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/my_plans/presentation/organisms/create_plan_modal.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/widget_finders.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

/// Validaciones y envío del modal "Crear Nuevo Plan" (HU de planes).
void main() {
  late _MockPlanRepository repository;

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  setUpAll(() => registerFallbackValue(const CreatePlanParams(title: 't')));

  Future<void> openModal(WidgetTester tester) async {
    useTallScreen(tester);
    repository = _MockPlanRepository();
    when(() => repository.getMyPlans()).thenAnswer((_) async => const <Plan>[]);
    final container = ProviderContainer(
      overrides: [planRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCreatePlanModal(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Guardar Plan'));
    await tester.pumpAndSettle();
  }

  testWidgets('el nombre es obligatorio', (tester) async {
    await openModal(tester);

    await save(tester);

    expect(find.text('Campo obligatorio'), findsOneWidget);
    verifyNever(() => repository.createPlan(any()));
  });

  testWidgets('un nombre de solo espacios cuenta como vacío', (tester) async {
    await openModal(tester);
    await tester.enterText(field('Nombre del plan'), '   ');
    await tester.enterText(field('Descripción (opcional)'), 'Algo');

    await save(tester);

    expect(find.text('Campo obligatorio'), findsOneWidget);
    verifyNever(() => repository.createPlan(any()));
  });

  testWidgets('el nombre no admite más de 255 caracteres', (tester) async {
    await openModal(tester);

    await tester.enterText(field('Nombre del plan'), 'a' * 300);
    await tester.pump();

    final text = tester.widget<TextField>(
      find.descendant(
        of: field('Nombre del plan'),
        matching: find.byType(TextField),
      ),
    );
    expect(text.controller!.text, hasLength(255));
  });

  testWidgets('acepta descripción y fecha vacías, y cierra sin excepción', (
    tester,
  ) async {
    await openModal(tester);
    when(() => repository.createPlan(any()))
        .thenAnswer((_) async => const Plan(id: 1, title: 'Asado'));
    await tester.enterText(field('Nombre del plan'), '  Asado  ');

    await save(tester);

    final params =
        verify(() => repository.createPlan(captureAny())).captured.single
            as CreatePlanParams;
    expect(params.title, 'Asado');
    expect(params.description, isEmpty);
    expect(params.meetingDate, isNull);
    expect(find.text('Crear Nuevo Plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con datos válidos crea el plan con fecha a las 18:00 y cierra', (
    tester,
  ) async {
    await openModal(tester);
    when(() => repository.createPlan(any()))
        .thenAnswer((_) async => const Plan(id: 1, title: 'Asado'));
    await tester.enterText(field('Nombre del plan'), '  Asado  ');
    await tester.enterText(field('Descripción (opcional)'), 'En casa');
    await tester.tap(field('Día de comienzo (Opcional)'));
    await tester.pumpAndSettle();
    final tomorrow = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    if (tomorrow.month != DateTime.now().month) {
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await save(tester);

    final params =
        verify(() => repository.createPlan(captureAny())).captured.single
            as CreatePlanParams;
    expect(params.title, 'Asado');
    expect(params.description, 'En casa');
    expect(
      params.meetingDate,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18),
    );
    expect(find.text('Crear Nuevo Plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('si el backend rechaza el plan muestra el error y no cierra', (
    tester,
  ) async {
    await openModal(tester);
    when(() => repository.createPlan(any()))
        .thenThrow(const ServerFailure('El título ya existe'));
    await tester.enterText(field('Nombre del plan'), 'Asado');
    await tester.enterText(field('Descripción (opcional)'), 'En casa');

    await save(tester);

    expect(find.text('El título ya existe'), findsOneWidget);
    expect(find.text('Crear Nuevo Plan'), findsOneWidget);
  });
}
