import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/route_paths.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/presentation/atoms/primary_button.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/pages/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/widget_finders.dart';

class _MockAuthRepository extends Mock implements AuthenticationRepository {}

const _emailHint = 'juanchavezzp@unicauca.edu.co';

/// Validación del correo (login_hint) y reacción a los estados del login.
void main() {
  late _MockAuthRepository repository;

  Future<void> pumpLogin(WidgetTester tester) async {
    useTallScreen(tester);
    repository = _MockAuthRepository();
    final router = GoRouter(
      initialLocation: RoutePaths.login,
      routes: [
        GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginPage()),
        GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const Text('pantalla de registro'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  VoidCallback? loginButton(WidgetTester tester) => tester
      .widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Iniciar Sesión'),
      )
      .onPressed;

  testWidgets('un correo mal escrito deshabilita el botón', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(fieldWithHint(_emailHint), 'ana@');
    await tester.pump();
    expect(loginButton(tester), isNull);

    await tester.enterText(fieldWithHint(_emailHint), 'ana@test.com');
    await tester.pump();
    expect(loginButton(tester), isNotNull);
  });

  testWidgets('al salir del campo con un correo inválido avisa', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(fieldWithHint(_emailHint));
    await tester.enterText(fieldWithHint(_emailHint), 'no-es-correo');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(
      find.text('El formato del correo electrónico no es válido.'),
      findsOneWidget,
    );
  });

  testWidgets('envía el correo como login_hint', (tester) async {
    await pumpLogin(tester);
    when(() => repository.login(loginHint: any(named: 'loginHint')))
        .thenThrow(const AuthenticationCancelledException());

    await tester.enterText(fieldWithHint(_emailHint), ' ana@test.com ');
    await tester.pump();
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    verify(() => repository.login(loginHint: 'ana@test.com')).called(1);
  });

  testWidgets('sin correo inicia sesión sin login_hint', (tester) async {
    await pumpLogin(tester);
    when(() => repository.login(loginHint: any(named: 'loginHint')))
        .thenThrow(const AuthenticationCancelledException());

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    verify(() => repository.login(loginHint: null)).called(1);
  });

  testWidgets('mientras Keycloak responde muestra la carga', (tester) async {
    await pumpLogin(tester);
    final pending = Completer<AuthSession>();
    when(() => repository.login(loginHint: any(named: 'loginHint')))
        .thenAnswer((_) => pending.future);

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    expect(find.text('Abriendo sesión con Keycloak...'), findsOneWidget);
    pending.completeError(const AuthenticationCancelledException());
    await tester.pump();
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('un error de credenciales se muestra al usuario', (tester) async {
    await pumpLogin(tester);
    when(() => repository.login(loginHint: any(named: 'loginHint')))
        .thenThrow(const AuthenticationException('invalid_grant'));

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Correo o contraseña incorrectos. Por favor, verifica tus datos.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el enlace de registro navega a /register', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla de registro'), findsOneWidget);
  });
}
