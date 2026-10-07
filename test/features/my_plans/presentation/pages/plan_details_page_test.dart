import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/my_plans/presentation/pages/plan_details_page.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

const _plan = Plan(id: 3, title: 'Mi concierto', userRole: 'CREATOR');
const _event = EventSeed(
  id: 7,
  title: 'Concierto',
  category: 'Música',
  eventText: 'Viernes',
);

void main() {
  late _MockPlanRepository repository;

  setUpAll(() {
    registerFallbackValue(const UpdatePlanParams(planId: 3, title: 'x'));
  });

  Future<void> openDetail(WidgetTester tester, Plan plan) async {
    repository = _MockPlanRepository();
    when(() => repository.getPlanEvents(plan.id))
        .thenAnswer((_) async => [_event]);
    final container = ProviderContainer(
      overrides: [planRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: PlanDetailsPage(plan: plan)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('quitar exige confirmar y solo borra el evento', (tester) async {
    await openDetail(tester, _plan);
    when(() => repository.removeEvent(3, 7)).thenAnswer((_) async {});

    await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
    await tester.pump();
    expect(find.text('¿Quitar evento?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(milliseconds: 300));
    verifyNever(() => repository.removeEvent(3, 7));

    await tester.tap(find.widgetWithText(TextButton, 'Quitar'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Quitar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => repository.removeEvent(3, 7)).called(1);
    expect(find.text('Evento quitado del plan.'), findsOneWidget);
    expect(find.text('Mi concierto'), findsOneWidget);
    expect(
      find.text('Todavía no hay eventos en este plan. Explora y guarda uno.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('editar muestra la confirmación superior tras guardar', (
    tester,
  ) async {
    await openDetail(tester, _plan);
    when(() => repository.updatePlan(any())).thenAnswer(
      (_) async =>
          const Plan(id: 3, title: 'Mi concierto editado', userRole: 'CREATOR'),
    );

    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repository.updatePlan(any())).called(1);
    expect(find.text('Plan actualizado.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('un participante puede ver eventos sin acciones de edición', (
    tester,
  ) async {
    await openDetail(
      tester,
      const Plan(id: 3, title: 'Plan invitado', userRole: 'GUEST'),
    );

    expect(find.text('Concierto'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Quitar'), findsNothing);
  });
}
