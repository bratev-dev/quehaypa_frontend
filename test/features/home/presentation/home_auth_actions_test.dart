import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/security/security_providers.dart';
import 'package:frontend/core/security/token_manager.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/home/presentation/organisms/home_auth_actions.dart';
import 'package:frontend/features/navigation/providers/navigation_provider.dart';
import 'package:frontend/features/organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements AuthenticationRepository {}

class _Tokens extends Mock implements TokenManager {}

void main() {
  testWidgets('la vista previa abre el dashboard y reinicia la navegación', (
    tester,
  ) async {
    final repository = _Repository();
    final tokens = _Tokens();
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
        tokenManagerProvider.overrideWithValue(tokens),
      ],
    );
    addTearDown(container.dispose);
    container.read(navigationIndexProvider.notifier).setIndex(3);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: HomeAuthActions())),
      ),
    );

    await tester.tap(find.text('Vista previa: organizador'));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizerDashboardPage), findsOneWidget);
    expect(container.read(navigationIndexProvider), 0);
    verifyNever(() => repository.login(loginHint: any(named: 'loginHint')));
    verifyNever(() => repository.register());
    expect(tester.takeException(), isNull);
  });

  for (final registering in [false, true]) {
    final label = registering ? 'Registrarse' : 'Iniciar Sesión';
    testWidgets('$label abre Keycloak y cancelar vuelve sin error', (
      tester,
    ) async {
      final repository = _Repository();
      final tokens = _Tokens();
      final pending = Completer<AuthSession>();
      when(() => tokens.isRegistrationPending()).thenAnswer((_) async => false);
      if (registering) {
        when(() => repository.register()).thenAnswer((_) => pending.future);
      } else {
        when(() => repository.login(loginHint: any(named: 'loginHint')))
            .thenAnswer((_) => pending.future);
      }
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
          tokenManagerProvider.overrideWithValue(tokens),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HomeAuthActions())),
        ),
      );
      await tester.tap(find.text(label));
      await tester.pump();
      expect(
        container.read(authenticationControllerProvider).status,
        AuthenticationStatus.loading,
      );
      for (final button in tester.widgetList<ElevatedButton>(
        find.byType(ElevatedButton),
      )) {
        expect(button.onPressed, isNull);
      }
      pending.completeError(const AuthenticationCancelledException());
      await tester.pump();
      expect(
        container.read(authenticationControllerProvider).status,
        AuthenticationStatus.unauthenticated,
      );
      expect(
        container.read(authenticationControllerProvider).errorMessage,
        isNull,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
      if (registering) {
        verify(() => repository.register()).called(1);
      } else {
        verify(() => repository.login(loginHint: null)).called(1);
      }
    });
  }
}
