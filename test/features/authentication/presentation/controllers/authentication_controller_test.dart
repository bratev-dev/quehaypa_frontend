import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers/network_providers.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/security/session_events_provider.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_http_adapter.dart';

class _MockAuthRepository extends Mock implements AuthenticationRepository {}

const _session = AuthSession(
  accessToken: 'acc',
  refreshToken: 'ref',
  idToken: 'idt',
);

const _user = {
  'id': 7,
  'username': 'ana.ruiz',
  'firstName': 'Ana',
  'lastName': 'Ruiz',
  'email': 'ana@test.com',
  'birthDate': '1998-02-15',
  'isActive': true,
};

void main() {
  late _MockAuthRepository repository;
  late FakeHttpAdapter adapter;
  late ProviderContainer container;

  AuthenticationController controller() =>
      container.read(authenticationControllerProvider.notifier);
  AuthenticationState state() =>
      container.read(authenticationControllerProvider);

  setUp(() {
    repository = _MockAuthRepository();
    adapter = FakeHttpAdapter();
    container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
        dioProvider.overrideWithValue(dioWith(adapter)),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial', () {
    expect(state().status, AuthenticationStatus.initial);
  });

  group('restoreSession', () {
    test('con sesión guardada queda autenticado', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _session);

      await controller().restoreSession();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().session?.accessToken, 'acc');
    });

    test('sin sesión queda no autenticado', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);

      await controller().restoreSession();

      expect(state().status, AuthenticationStatus.unauthenticated);
    });

    test('si restaurar falla queda no autenticado', () async {
      when(() => repository.restoreSession())
          .thenThrow(const StorageException('x'));

      await controller().restoreSession();

      expect(state().status, AuthenticationStatus.unauthenticated);
    });
  });

  group('login', () {
    test(
      'usuario regular: autentica e hidrata los intereses del dashboard',
      () async {
        when(() => repository.login(loginHint: 'ana@test.com'))
            .thenAnswer((_) async => _session);
        adapter.queue.addAll([
          const FakeReply(200, {'data': _user}),
          const FakeReply(200, {
            'data': ['Cine', 'Arte'],
          }),
        ]);

        await controller().login(loginHint: 'ana@test.com');

        expect(state().status, AuthenticationStatus.authenticated);
        expect(adapter.requests.map((r) => r.path), [
          '/api/v1/regular-users/me',
          '/api/v1/preferences/me',
        ]);
        expect(container.read(dashboardControllerProvider).userInterests, [
          'Cine',
          'Arte',
        ]);
      },
    );

    test(
      'regular sin preferencias guardadas igual queda autenticado',
      () async {
        when(() => repository.login(loginHint: any(named: 'loginHint')))
            .thenAnswer((_) async => _session);
        adapter.queue.addAll([
          const FakeReply(200, {'data': _user}),
          const FakeReply(404, {'message': 'Sin preferencias'}),
        ]);

        await controller().login();

        expect(state().status, AuthenticationStatus.authenticated);
      },
    );

    test('si no es regular consulta el perfil de organizador', () async {
      when(() => repository.login(loginHint: any(named: 'loginHint')))
          .thenAnswer((_) async => _session);
      adapter.queue.add(const FakeReply(404, {'message': 'No es regular'}));
      adapter.reply = const FakeReply(404, {'message': 'Sin perfil'});

      await controller().login();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(adapter.last.path, '/api/v1/organizers/me');
    });

    test('cancelar en Keycloak vuelve a no autenticado sin error', () async {
      when(() => repository.login(loginHint: any(named: 'loginHint')))
          .thenThrow(const AuthenticationCancelledException());

      await controller().login();

      expect(state().status, AuthenticationStatus.unauthenticated);
      expect(state().errorMessage, isNull);
    });

    test('credenciales inválidas dejan un mensaje amigable', () async {
      when(() => repository.login(loginHint: any(named: 'loginHint')))
          .thenThrow(const AuthenticationException('invalid_grant'));

      await controller().login();

      expect(state().status, AuthenticationStatus.error);
      expect(state().errorMessage, contains('Correo o contraseña incorrectos'));
    });
  });

  group('logout', () {
    test('cierra sesión y queda no autenticado', () async {
      when(() => repository.logout()).thenAnswer((_) async {});

      final success = await controller().logout();

      expect(success, isTrue);
      expect(state().status, AuthenticationStatus.unauthenticated);
    });

    test('si falla el cierre remoto deja la sesión local cerrada y el error amigable', () async {
      when(() => repository.logout()).thenThrow(Exception('SocketException'));

      final success = await controller().logout();

      expect(success, isFalse);
      expect(state().status, AuthenticationStatus.unauthenticated);
      expect(state().errorMessage, contains('No pudimos conectar'));
    });
  });

  test(
    'una sesión invalidada (refresco fallido) cierra la sesión en la UI',
    () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _session);
      await controller().restoreSession();
      container.listen(sessionInvalidatedProvider, (_, _) {});

      container.read(sessionEventsProvider).notifySessionInvalidated();
      await Future<void>.delayed(Duration.zero);

      expect(state().status, AuthenticationStatus.unauthenticated);
    },
  );
}
