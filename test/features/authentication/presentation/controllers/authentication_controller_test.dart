import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/security/session_events_provider.dart';
import 'package:frontend/core/security/security_providers.dart';
import 'package:frontend/core/security/token_manager.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/registration_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/manage_registration_use_case.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_http_adapter.dart';

class _MockAuthRepository extends Mock implements AuthenticationRepository {}

class _MockTokenManager extends Mock implements TokenManager {}

class _MockRegistrationRepository extends Mock
    implements RegistrationRepository {}

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

const _organizer = {
  'id': 9,
  'username': 'org.cauca',
  'firstName': 'Org',
  'lastName': 'Cauca',
  'email': 'org@test.com',
  'identificationDocument': '1061000000',
  'isActive': true,
};

void main() {
  late _MockAuthRepository repository;
  late _MockTokenManager tokens;
  late _MockRegistrationRepository registrations;
  late FakeHttpAdapter adapter;
  late ProviderContainer container;

  AuthenticationController controller() =>
      container.read(authenticationControllerProvider.notifier);
  AuthenticationState state() =>
      container.read(authenticationControllerProvider);

  setUp(() {
    repository = _MockAuthRepository();
    tokens = _MockTokenManager();
    registrations = _MockRegistrationRepository();
    when(() => registrations.begin()).thenAnswer((_) async => false);
    when(() => registrations.complete()).thenAnswer((_) async {});
    when(() => registrations.cancel()).thenAnswer((_) async {});
    when(() => tokens.isRegistrationPending()).thenAnswer((_) async => false);
    when(() => tokens.setRegistrationPending(any())).thenAnswer((_) async {});
    adapter = FakeHttpAdapter();
    container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
        tokenManagerProvider.overrideWithValue(tokens),
        manageRegistrationUseCaseProvider.overrideWithValue(
          ManageRegistrationUseCase(registrations),
        ),
        dioProvider.overrideWithValue(dioWith(adapter)),
      ],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial', () {
    expect(state().status, AuthenticationStatus.initial);
    expect(state().isOrganizer, isFalse);
  });

  test('copyWith conserva o actualiza el rol de organizador', () {
    const initial = AuthenticationState(
      status: AuthenticationStatus.authenticated,
      isOrganizer: true,
    );
    expect(
      initial.copyWith(status: AuthenticationStatus.loading).isOrganizer,
      isTrue,
    );
    expect(initial.copyWith(isOrganizer: false).isOrganizer, isFalse);
  });

  group('restoreSession', () {
    test('registro incompleto vuelve a rol al reabrir la aplicación', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _session);
      when(() => tokens.isRegistrationPending()).thenAnswer((_) async => true);
      when(() => registrations.begin()).thenAnswer((_) async => true);
      await controller().restoreSession();
      expect(state().status, AuthenticationStatus.registrationRequired);
      expect(
        container.read(registerControllerProvider).currentStep,
        RegisterStep.roleSelection,
      );
    });
    test('con sesión guardada queda autenticado', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _session);

      await controller().restoreSession();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().session?.accessToken, 'acc');
      expect(state().isOrganizer, isFalse);
    });

    test('sesión guardada de organizador recupera su dashboard', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _session);
      adapter.queue.addAll([
        const FakeReply(404, {'message': 'No es regular'}),
        const FakeReply(200, {'data': _organizer}),
      ]);

      await controller().restoreSession();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().isOrganizer, isTrue);
      expect(adapter.requests.map((request) => request.path), [
        '/api/v1/regular-users/me',
        '/api/v1/organizers/me',
      ]);
    });

    test(
      'marca local antigua no convierte una cuenta completa en pendiente',
      () async {
        when(() => repository.restoreSession())
            .thenAnswer((_) async => _session);
        when(() => tokens.isRegistrationPending())
            .thenAnswer((_) async => true);
        await controller().restoreSession();
        expect(state().status, AuthenticationStatus.authenticated);
        expect(state().isOrganizer, isFalse);
        verify(() => tokens.setRegistrationPending(false)).called(1);
      },
    );

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
      expect(state().isOrganizer, isFalse);
    });

    test(
      'perfil de organizador habilita su dashboard al iniciar sesión',
      () async {
        when(() => repository.login(loginHint: any(named: 'loginHint')))
            .thenAnswer((_) async => _session);
        adapter.queue.addAll([
          const FakeReply(404, {'message': 'No es regular'}),
          const FakeReply(200, {'data': _organizer}),
        ]);

        await controller().login();

        expect(state().status, AuthenticationStatus.authenticated);
        expect(state().isOrganizer, isTrue);
        expect(adapter.last.path, '/api/v1/organizers/me');
      },
    );

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

  group('registro desde el vídeo', () {
    setUp(() {
      when(() => registrations.begin()).thenAnswer((_) async => true);
    });
    test(
      'Keycloak completado deja el registro pendiente de elegir rol',
      () async {
        when(() => repository.register()).thenAnswer((_) async => _session);

        await controller().register();

        expect(state().status, AuthenticationStatus.registrationRequired);
        expect(state().session, same(_session));
        expect(
          container.read(registerControllerProvider).currentStep,
          RegisterStep.roleSelection,
        );
        expect(adapter.requests, isEmpty);
        verify(() => repository.register()).called(1);
      },
    );

    test('cancelar no avanza ni muestra error', () async {
      when(() => repository.register())
          .thenThrow(const AuthenticationCancelledException());

      await controller().register();

      expect(state().status, AuthenticationStatus.unauthenticated);
      expect(state().session, isNull);
      expect(state().errorMessage, isNull);
      expect(adapter.requests, isEmpty);
    });

    test('registro ya completo resuelve el perfil de organizador', () async {
      when(() => registrations.begin()).thenAnswer((_) async => false);
      when(() => repository.register()).thenAnswer((_) async => _session);
      adapter.queue.addAll([
        const FakeReply(404, {'message': 'No es regular'}),
        const FakeReply(200, {'data': _organizer}),
      ]);

      await controller().register();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().isOrganizer, isTrue);
    });

    test('un fallo real conserva un mensaje amigable', () async {
      when(() => repository.register())
          .thenThrow(const AuthenticationException('SocketException'));
      await controller().register();
      expect(state().status, AuthenticationStatus.error);
      expect(state().errorMessage, contains('No pudimos conectar'));
    });

    test(
      'tras completar el perfil refresca sin abrir Keycloak de nuevo',
      () async {
        when(() => repository.register()).thenAnswer((_) async => _session);
        when(() => repository.refreshSession())
            .thenAnswer((_) async => _session);
        await controller().register();
        await controller().finishRegistration();
        expect(state().status, AuthenticationStatus.authenticated);
        verify(() => repository.register()).called(1);
        verify(() => repository.refreshSession()).called(1);
        verify(() => tokens.setRegistrationPending(false)).called(1);
      },
    );

    test('finalizar el registro de organizador conserva su rol', () async {
      when(() => repository.register()).thenAnswer((_) async => _session);
      when(() => repository.refreshSession()).thenAnswer((_) async => _session);
      await controller().register();
      container
          .read(registerControllerProvider.notifier)
          .selectRole(UserRole.organizer);

      await controller().finishRegistration();

      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().isOrganizer, isTrue);
    });

    test('un fallo de refresh no repite el registro', () async {
      when(() => repository.register()).thenAnswer((_) async => _session);
      when(() => repository.refreshSession())
          .thenThrow(const AuthenticationException('red'));
      await controller().register();
      await controller().finishRegistration();
      expect(state().status, AuthenticationStatus.authenticated);
      expect(state().session, same(_session));
      verify(() => repository.register()).called(1);
    });
  });

  group('logout', () {
    test('renovar perfil actualiza sesión sin volver a autenticar', () async {
      when(() => repository.refreshSession()).thenAnswer((_) async => _session);
      expect(await controller().refreshProfileSession(), isTrue);
      expect(state().session, same(_session));
      verifyNever(() => repository.login(loginHint: any(named: 'loginHint')));
    });

    test(
      'renovar perfil fallido conserva estado y permite informar al usuario',
      () async {
        when(() => repository.refreshSession())
            .thenThrow(const AuthenticationException('offline'));
        expect(await controller().refreshProfileSession(), isFalse);
        expect(state().status, AuthenticationStatus.initial);
      },
    );
    test('cancela remotamente antes de cerrar la sesión', () async {
      when(() => repository.register()).thenAnswer((_) async => _session);
      when(() => registrations.begin()).thenAnswer((_) async => true);
      when(() => repository.logout()).thenAnswer((_) async {});
      await controller().register();
      expect(await controller().cancelRegistration(), isTrue);
      verifyInOrder([() => registrations.cancel(), () => repository.logout()]);
      expect(state().status, AuthenticationStatus.unauthenticated);
    });

    test('cancelación fallida conserva sesión y permite reintentar', () async {
      when(() => repository.register()).thenAnswer((_) async => _session);
      when(() => registrations.begin()).thenAnswer((_) async => true);
      when(() => registrations.cancel())
          .thenThrow(const NetworkFailure('Sin conexión'));
      await controller().register();
      expect(await controller().cancelRegistration(), isFalse);
      expect(state().status, AuthenticationStatus.registrationRequired);
      expect(
        container.read(registerControllerProvider).errorMessage,
        contains('Sin conexión'),
      );
      verifyNever(() => repository.logout());
      when(() => registrations.cancel()).thenAnswer((_) async {});
      when(() => repository.logout()).thenAnswer((_) async {});
      expect(await controller().cancelRegistration(), isTrue);
    });

    test('registro remoto pendiente prevalece sobre la marca local', () async {
      when(() => repository.login(loginHint: any(named: 'loginHint')))
          .thenAnswer((_) async => _session);
      when(() => registrations.begin()).thenAnswer((_) async => true);
      await controller().login();
      expect(state().status, AuthenticationStatus.registrationRequired);
      expect(adapter.requests, isEmpty);
    });

    test('fallo al finalizar remotamente no habilita dashboard', () async {
      when(() => repository.register()).thenAnswer((_) async => _session);
      when(() => registrations.begin()).thenAnswer((_) async => true);
      when(() => registrations.complete())
          .thenThrow(const ServerFailure('Reintenta'));
      await controller().register();
      await controller().finishRegistration();
      expect(state().status, AuthenticationStatus.registrationRequired);
      expect(
        container.read(registerControllerProvider).errorMessage,
        'Reintenta',
      );
      verifyNever(() => tokens.setRegistrationPending(false));
    });

    test('cierra sesión y queda no autenticado', () async {
      when(() => repository.logout()).thenAnswer((_) async {});
      container.read(dashboardControllerProvider.notifier).setUserInterests([
        'Cine',
      ]);

      final success = await controller().logout();

      expect(success, isTrue);
      expect(state().status, AuthenticationStatus.unauthenticated);
      expect(
        container.read(dashboardControllerProvider).userInterests,
        isEmpty,
      );
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
