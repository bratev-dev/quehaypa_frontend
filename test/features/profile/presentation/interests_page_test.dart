import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/atoms/interest_chip.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:frontend/features/profile/presentation/pages/interests_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/widget_finders.dart';

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

const _catalog = [
  Interest(id: 1, name: 'Música'),
  Interest(id: 2, name: 'Cine'),
  Interest(id: 3, name: 'Arte'),
  Interest(id: 4, name: 'Teatro'),
  Interest(id: 5, name: 'Danza'),
];

void main() {
  late _MockPreferencesRepository repository;
  late ProviderContainer container;

  Future<void> pumpPage(WidgetTester tester) async {
    useTallScreen(tester);
    container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const InterestsPage(),
                  ),
                ),
                child: const Text('Abrir intereses'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir intereses'));
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    repository = _MockPreferencesRepository();
    when(() => repository.getInterests()).thenAnswer((_) async => _catalog);
    when(() => repository.getMyPreferences())
        .thenAnswer((_) async => ['Música', 'Cine', 'Arte']);
  });

  testWidgets('carga la selección guardada y exige cuatro intereses', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Selecciona al menos 4 intereses (3/4)'), findsOneWidget);
    expect(
      tester.widget<InterestChip>(find.byType(InterestChip).first).isSelected,
      isTrue,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Teatro'));
    await tester.pump();
    expect(find.text('Selecciona al menos 4 intereses (4/4)'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Teatro'));
    await tester.pump();
    expect(find.text('Selecciona al menos 4 intereses (3/4)'), findsOneWidget);
  });

  testWidgets('guarda intereses y actualiza los del dashboard', (tester) async {
    when(() => repository.saveMyPreferences(any()))
        .thenAnswer((_) async => ['Música', 'Cine', 'Arte', 'Teatro']);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teatro'));
    await tester.pump();
    await tester.tap(find.text('Guardar intereses'));
    await tester.pumpAndSettle();

    verify(
      () => repository.saveMyPreferences(['Música', 'Cine', 'Arte', 'Teatro']),
    ).called(1);
    expect(container.read(dashboardControllerProvider).userInterests, [
      'Música',
      'Cine',
      'Arte',
      'Teatro',
    ]);
    expect(find.text('Abrir intereses'), findsOneWidget);
  });

  testWidgets('permite reintentar si falla la carga', (tester) async {
    when(() => repository.getMyPreferences())
        .thenThrow(Exception('Sin conexión'));
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No pudimos recuperar tus intereses guardados'),
      findsOneWidget,
    );
    expect(find.text('Guardar intereses'), findsNothing);

    when(() => repository.getMyPreferences())
        .thenAnswer((_) async => ['Música', 'Cine', 'Arte', 'Teatro']);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona al menos 4 intereses (4/4)'), findsOneWidget);
    verify(() => repository.getMyPreferences()).called(2);
  });

  testWidgets('deshabilita guardar mientras espera y recupera tras error', (
    tester,
  ) async {
    final pending = Completer<List<String>>();
    when(() => repository.saveMyPreferences(any()))
        .thenAnswer((_) => pending.future);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teatro'));
    await tester.pump();
    await tester.tap(find.text('Guardar intereses'));
    await tester.pump();
    expect(find.text('Guardando…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.completeError(Exception('Servidor no disponible'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.textContaining('No se pudieron guardar los intereses'),
      findsOneWidget,
    );
    expect(find.text('Guardar intereses'), findsOneWidget);
  });
}
