import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/my_plans/presentation/organisms/edit_plan_modal.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/widget_finders.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late _MockPlanRepository repository;
  final original = Plan(
    id: 3,
    title: 'Noche de jazz',
    description: 'Con amigos',
    meetingDate: DateTime(2020, 1, 2, 18),
    userRole: 'CREATOR',
  );

  setUpAll(() {
    registerFallbackValue(const UpdatePlanParams(planId: 3, title: 'x'));
  });

  Future<void> openModal(WidgetTester tester) async {
    useTallScreen(tester);
    repository = _MockPlanRepository();
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
                onPressed: () => showEditPlanModal(context, original),
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

  testWidgets('precarga y conserva una fecha histórica sin cambiarla', (
    tester,
  ) async {
    await openModal(tester);
    when(() => repository.updatePlan(any())).thenAnswer((_) async => original);

    expect(find.text('Noche de jazz'), findsOneWidget);
    expect(find.text('Con amigos'), findsOneWidget);
    expect(find.text('2020-01-02'), findsOneWidget);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final params =
        verify(() => repository.updatePlan(captureAny())).captured.single
            as UpdatePlanParams;
    expect(params.meetingDate, DateTime(2020, 1, 2, 18));
    expect(find.text('Editar plan'), findsNothing);
  });

  testWidgets('permite borrar descripción y fecha de un plan', (tester) async {
    await openModal(tester);
    when(() => repository.updatePlan(any())).thenAnswer(
      (_) async => const Plan(id: 3, title: 'Plan nuevo', userRole: 'CREATOR'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del plan'),
      'Plan nuevo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción (opcional)'),
      '',
    );
    await tester.tap(find.byTooltip('Quitar fecha'));
    await tester.pump();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final params =
        verify(() => repository.updatePlan(captureAny())).captured.single
            as UpdatePlanParams;
    expect(params.title, 'Plan nuevo');
    expect(params.description, isEmpty);
    expect(params.meetingDate, isNull);
  });

  testWidgets('ante un error conserva el formulario para reintentar', (
    tester,
  ) async {
    await openModal(tester);
    when(() => repository.updatePlan(any()))
        .thenThrow(const ServerFailure('No se pudo guardar'));

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Editar plan'), findsOneWidget);
    expect(find.text('Noche de jazz'), findsOneWidget);
    expect(find.text('No se pudo guardar'), findsOneWidget);
  });

  testWidgets('cancelar no envía cambios', (tester) async {
    await openModal(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del plan'),
      'Nombre temporal',
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.updatePlan(any()));
    expect(find.text('Editar plan'), findsNothing);
  });
}
