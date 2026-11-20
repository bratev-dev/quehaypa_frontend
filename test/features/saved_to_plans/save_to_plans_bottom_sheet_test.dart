import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/saved_to_plans/presentation/atoms/plan_selector_icon_atom.dart';
import 'package:frontend/features/saved_to_plans/presentation/modals/save_to_plans_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_finders.dart';

class _PlanRepository extends Mock implements PlanRepository {}

void main() {
  testWidgets('crea un plan propio y reintenta guardar en el mismo plan', (
    tester,
  ) async {
    useTallScreen(tester);
    registerFallbackValue(const CreatePlanParams(title: 'Plan'));
    final repository = _PlanRepository();
    const ownPlan = Plan(id: 7, title: 'Mi plan', userRole: 'CREATOR');
    const otherPlan = Plan(id: 3, title: 'Plan ajeno');
    const event = EventSeed(
      id: 42,
      title: 'Concierto',
      category: 'Música',
      eventText: 'Hoy',
    );
    final plans = [otherPlan];
    final events = <EventSeed>[];
    when(() => repository.getMyPlans()).thenAnswer((_) async => [...plans]);
    when(() => repository.getPlanEvents(7))
        .thenAnswer((_) async => [...events]);
    when(() => repository.createPlan(any())).thenAnswer((_) async {
      plans.add(ownPlan);
      return ownPlan;
    });
    var attempts = 0;
    when(() => repository.addEvent(7, 42)).thenAnswer((_) async {
      if (++attempts == 1) throw const NetworkFailure('Sin conexión');
      events.add(event);
      return event;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [planRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSaveToPlansBottomSheet(
                    context,
                    eventId: event.id,
                    eventTitle: event.title,
                  ),
                  child: const Text('Elegir plan'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Elegir plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Plan ajeno'), findsNothing);
    await tester.tap(find.text('Crear mi primer plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextFormField).first, 'Mi plan');
    await tester.tap(find.text('Crear plan y guardar evento'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Mi plan'), findsOneWidget);

    final selector = find.byType(PlanSelectorIconAtom);
    await tester.tap(selector);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Evento guardado en "Mi plan".'), findsOneWidget);
    verify(() => repository.createPlan(any())).called(1);
    verify(() => repository.addEvent(7, 42)).called(2);

    Navigator.of(tester.element(selector)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Elegir plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<PlanSelectorIconAtom>(selector).isSelected, isTrue);
    await tester.tap(selector);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Este evento ya está guardado en ese plan.'),
      findsOneWidget,
    );
    verifyNever(() => repository.addEvent(any(), any()));
    await tester.pump(const Duration(seconds: 3));
  });
}
