import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/organisms/interests_selection_form.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/widget_finders.dart';

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

/// Registra si se intentó completar el registro, sin llamar a Keycloak.
class _SpyRegisterController extends RegisterController {
  int completions = 0;

  @override
  Future<void> completeRegistration() async => completions++;
}

const _catalogo = [
  Interest(id: 1, name: 'Música'),
  Interest(id: 2, name: 'Cine'),
  Interest(id: 3, name: 'Arte'),
  Interest(id: 4, name: 'Teatro'),
  Interest(id: 5, name: 'Danza'),
];

/// Regla de negocio del registro: mínimo 4 intereses (HU-1.2).
void main() {
  late _MockPreferencesRepository repository;
  late ProviderContainer container;
  late _SpyRegisterController register;

  Future<void> pumpForm(WidgetTester tester) async {
    useTallScreen(tester);
    register = _SpyRegisterController();
    container = ProviderContainer(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(repository),
        registerControllerProvider.overrideWith(() => register),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: InterestsSelectionForm()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, List<String> names) async {
    for (final name in names) {
      await tester.tap(find.text(name));
      await tester.pump();
    }
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.tap(find.text('Finalizar Registro'));
    await tester.pump();
  }

  setUp(() {
    repository = _MockPreferencesRepository();
    when(() => repository.getInterests()).thenAnswer((_) async => _catalogo);
  });

  testWidgets('muestra el catálogo real del backend', (tester) async {
    await pumpForm(tester);

    for (final interest in _catalogo) {
      expect(find.text(interest.name), findsOneWidget);
    }
    expect(find.text('Tecnología'), findsNothing);
  });

  testWidgets('con menos de 4 intereses no deja finalizar', (tester) async {
    await pumpForm(tester);
    await choose(tester, ['Música', 'Cine', 'Arte']);

    expect(find.text('Selecciona al menos 4 intereses (3/4)'), findsOneWidget);
    await finish(tester);

    expect(
      find.text('Selecciona al menos 4 intereses para continuar.'),
      findsOneWidget,
    );
    expect(register.completions, 0);
  });

  testWidgets('tocar un interés elegido lo quita de la selección', (
    tester,
  ) async {
    await pumpForm(tester);
    await choose(tester, ['Música', 'Música']);

    expect(find.text('Selecciona al menos 4 intereses (0/4)'), findsOneWidget);
  });

  testWidgets('con 4 intereses completa el registro', (tester) async {
    await pumpForm(tester);
    await choose(tester, ['Música', 'Cine', 'Arte', 'Teatro']);

    await finish(tester);

    expect(register.completions, 1);
    expect(container.read(registerControllerProvider).selectedInterests, [
      'Música',
      'Cine',
      'Arte',
      'Teatro',
    ]);
  });

  testWidgets('sin catálogo no inventa intereses y permite reintentar', (
    tester,
  ) async {
    when(() => repository.getInterests())
        .thenThrow(const NetworkFailure('Sin conexión'));
    await pumpForm(tester);

    expect(
      find.text('No pudimos cargar el catálogo de intereses. Reintenta.'),
      findsOneWidget,
    );
    expect(find.text('Tecnología'), findsNothing);
    await finish(tester);
    expect(register.completions, 0);

    when(() => repository.getInterests()).thenAnswer((_) async => _catalogo);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(find.text('Teatro'), findsOneWidget);
  });

  testWidgets('catálogo vacío no permite finalizar con intereses inventados', (
    tester,
  ) async {
    when(() => repository.getInterests()).thenAnswer((_) async => []);
    await pumpForm(tester);
    expect(
      find.text('No hay intereses disponibles por ahora.'),
      findsOneWidget,
    );
    expect(find.text('Tecnología'), findsNothing);
    await finish(tester);
    expect(register.completions, 0);
  });

  testWidgets('mientras carga el catálogo muestra un indicador', (
    tester,
  ) async {
    final pending = Completer<List<Interest>>();
    when(() => repository.getInterests()).thenAnswer((_) => pending.future);
    await pumpForm(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(_catalogo);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
