import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:frontend/features/profile/presentation/profile_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/widget_finders.dart';

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  const user = User(
    id: 7,
    username: 'juan',
    firstName: 'Juan',
    lastName: 'Chávez',
    email: 'juan@example.com',
    isActive: true,
  );

  late _MockUserRepository repository;

  Future<void> pumpPage(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(repository),
          myProfileProvider.overrideWith((ref) async => user),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfilePage(user: user),
                  ),
                ),
                child: const Text('Abrir edición'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir edición'));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = _MockUserRepository());

  testWidgets('muestra los datos actuales y exige nombre y apellido', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('@juan'), findsOneWidget);
    expect(find.text('juan@example.com'), findsOneWidget);
    final fields = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, 'Juan');
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'Chávez',
    );

    await tester.enterText(fields.at(0), '   ');
    await tester.enterText(fields.at(1), '');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Escribe tu Nombre'), findsOneWidget);
    expect(find.text('Escribe tu Apellido'), findsOneWidget);
    verifyNever(
      () => repository.updateProfile(
        id: any(named: 'id'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        birthDate: any(named: 'birthDate'),
      ),
    );
  });

  testWidgets('guarda nombres recortados y vuelve a configuración', (
    tester,
  ) async {
    when(
      () => repository.updateProfile(
        id: 7,
        firstName: 'Ana',
        lastName: 'Pérez',
        birthDate: null,
      ),
    ).thenAnswer((_) async => user);
    await pumpPage(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Ana  ');
    await tester.enterText(fields.at(1), ' Pérez ');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateProfile(
        id: 7,
        firstName: 'Ana',
        lastName: 'Pérez',
        birthDate: null,
      ),
    ).called(1);
    expect(find.text('Abrir edición'), findsOneWidget);
  });

  testWidgets('impide repetir el guardado y muestra el error del servidor', (
    tester,
  ) async {
    final pending = Completer<User>();
    when(
      () => repository.updateProfile(
        id: 7,
        firstName: 'Juan',
        lastName: 'Chávez',
        birthDate: null,
      ),
    ).thenAnswer((_) => pending.future);
    await pumpPage(tester);

    await tester.tap(find.text('Guardar cambios'));
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
      find.textContaining('No se pudieron guardar los cambios'),
      findsOneWidget,
    );
    expect(find.text('Guardar cambios'), findsOneWidget);
    verify(
      () => repository.updateProfile(
        id: 7,
        firstName: 'Juan',
        lastName: 'Chávez',
        birthDate: null,
      ),
    ).called(1);
  });
}
