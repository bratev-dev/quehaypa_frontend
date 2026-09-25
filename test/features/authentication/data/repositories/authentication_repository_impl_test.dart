import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/security/token_manager.dart';
import 'package:frontend/features/authentication/data/datasources/keycloak_data_source.dart';
import 'package:frontend/features/authentication/data/models/auth_session_model.dart';
import 'package:frontend/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeycloak extends Mock implements KeycloakDataSource {}

class _MockTokenManager extends Mock implements TokenManager {}

void main() {
  late _MockKeycloak keycloak;
  late _MockTokenManager tokens;
  late AuthenticationRepositoryImpl repository;

  const session = AuthSessionModel(
    accessToken: 'acc',
    refreshToken: 'ref',
    idToken: 'idt',
  );

  void tokensSaved() => when(
    () => tokens.saveTokens(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
      idToken: any(named: 'idToken'),
    ),
  ).thenAnswer((_) async {});

  void verifySaved() => verify(
    () => tokens.saveTokens(
      accessToken: 'acc',
      refreshToken: 'ref',
      idToken: 'idt',
    ),
  ).called(1);

  setUp(() {
    keycloak = _MockKeycloak();
    tokens = _MockTokenManager();
    repository = AuthenticationRepositoryImpl(
      keycloakDataSource: keycloak,
      tokenManager: tokens,
    );
    when(() => tokens.clearSession()).thenAnswer((_) async {});
  });

  group('login', () {
    test('guarda los tokens y devuelve la sesión', () async {
      when(() => keycloak.login(loginHint: 'a@b.co'))
          .thenAnswer((_) async => session);
      tokensSaved();

      final result = await repository.login(loginHint: 'a@b.co');

      expect(result.accessToken, 'acc');
      verifySaved();
    });

    test('propaga la cancelación del usuario', () {
      when(() => keycloak.login(loginHint: any(named: 'loginHint')))
          .thenThrow(const AuthenticationCancelledException());

      expect(
        repository.login(),
        throwsA(isA<AuthenticationCancelledException>()),
      );
    });

    test('propaga AuthenticationException', () {
      when(() => keycloak.login(loginHint: any(named: 'loginHint')))
          .thenThrow(const AuthenticationException('credenciales'));

      expect(repository.login(), throwsA(isA<AuthenticationException>()));
    });

    test('un fallo al guardar se convierte en AuthenticationException', () {
      when(() => keycloak.login(loginHint: any(named: 'loginHint')))
          .thenAnswer((_) async => session);
      when(
        () => tokens.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          idToken: any(named: 'idToken'),
        ),
      ).thenThrow(StateError('almacenamiento'));

      expect(
        repository.login(),
        throwsA(
          isA<AuthenticationException>().having(
            (e) => e.message,
            'message',
            contains('inicio de sesion'),
          ),
        ),
      );
    });
  });

  group('register', () {
    test('guarda los tokens y devuelve la sesión', () async {
      when(() => keycloak.register()).thenAnswer((_) async => session);
      tokensSaved();

      expect((await repository.register()).idToken, 'idt');
      verifySaved();
    });

    test('propaga AuthenticationException', () {
      when(() => keycloak.register())
          .thenThrow(const AuthenticationException('x'));

      expect(repository.register(), throwsA(isA<AuthenticationException>()));
    });

    test('otro error se convierte en AuthenticationException', () {
      when(() => keycloak.register()).thenThrow(StateError('x'));

      expect(
        repository.register(),
        throwsA(
          isA<AuthenticationException>().having(
            (e) => e.message,
            'message',
            contains('registro'),
          ),
        ),
      );
    });
  });

  group('refreshSession', () {
    test('sin refresh token lanza AuthenticationException', () {
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => null);

      expect(
        repository.refreshSession(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('renueva con Keycloak y guarda los tokens nuevos', () async {
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'viejo');
      when(() => keycloak.refreshSession('viejo'))
          .thenAnswer((_) async => session);
      tokensSaved();

      expect((await repository.refreshSession()).accessToken, 'acc');
      verifySaved();
    });

    test('propaga AuthenticationException de Keycloak', () {
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'viejo');
      when(() => keycloak.refreshSession(any()))
          .thenThrow(const AuthenticationException('x'));

      expect(
        repository.refreshSession(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('otro error se convierte en AuthenticationException', () {
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'viejo');
      when(() => keycloak.refreshSession(any())).thenThrow(StateError('x'));

      expect(
        repository.refreshSession(),
        throwsA(
          isA<AuthenticationException>().having(
            (e) => e.message,
            'message',
            contains('renovar'),
          ),
        ),
      );
    });
  });

  group('restoreSession', () {
    test('sin access token devuelve null', () async {
      when(() => tokens.getAccessToken()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), isNull);
    });

    test('con sesión vigente la reconstruye desde el almacenamiento', () async {
      when(() => tokens.getAccessToken()).thenAnswer((_) async => 'acc');
      when(() => tokens.hasSession()).thenAnswer((_) async => true);
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(() => tokens.getIdToken()).thenAnswer((_) async => 'idt');

      final restored = await repository.restoreSession();

      expect(restored?.refreshToken, 'ref');
      verifyNever(() => keycloak.refreshSession(any()));
    });

    test(
      'vencida y sin refresh token limpia la sesión y devuelve null',
      () async {
        when(() => tokens.getAccessToken()).thenAnswer((_) async => 'acc');
        when(() => tokens.hasSession()).thenAnswer((_) async => false);
        when(() => tokens.getRefreshToken()).thenAnswer((_) async => '');

        expect(await repository.restoreSession(), isNull);
        verify(() => tokens.clearSession()).called(1);
      },
    );

    test('vencida con refresh token la renueva', () async {
      when(() => tokens.getAccessToken()).thenAnswer((_) async => 'viejo');
      when(() => tokens.hasSession()).thenAnswer((_) async => false);
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(() => keycloak.refreshSession('ref'))
          .thenAnswer((_) async => session);
      tokensSaved();

      expect((await repository.restoreSession())?.accessToken, 'acc');
    });

    test('si la renovación falla limpia la sesión y devuelve null', () async {
      when(() => tokens.getAccessToken()).thenAnswer((_) async => 'viejo');
      when(() => tokens.hasSession()).thenAnswer((_) async => false);
      when(() => tokens.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(() => keycloak.refreshSession(any()))
          .thenThrow(const AuthenticationException('x'));

      expect(await repository.restoreSession(), isNull);
      verify(() => tokens.clearSession()).called(1);
    });

    test('un error de almacenamiento se convierte en StorageException', () {
      when(() => tokens.getAccessToken()).thenThrow(StateError('keystore'));

      expect(repository.restoreSession(), throwsA(isA<StorageException>()));
    });
  });

  group('logout', () {
    test(
      'con id token cierra sesión en Keycloak y limpia los tokens',
      () async {
        when(() => tokens.getIdToken()).thenAnswer((_) async => 'idt');
        when(() => keycloak.logout('idt')).thenAnswer((_) async {});

        await repository.logout();

        verify(() => keycloak.logout('idt')).called(1);
        verify(() => tokens.clearSession()).called(1);
      },
    );

    test('sin id token solo limpia los tokens', () async {
      when(() => tokens.getIdToken()).thenAnswer((_) async => null);

      await repository.logout();

      verifyNever(() => keycloak.logout(any()));
      verify(() => tokens.clearSession()).called(1);
    });

    test('si Keycloak falla igual limpia los tokens', () async {
      when(() => tokens.getIdToken()).thenAnswer((_) async => 'idt');
      when(() => keycloak.logout(any()))
          .thenThrow(const AuthenticationException('x'));

      await expectLater(
        repository.logout(),
        throwsA(isA<AuthenticationException>()),
      );
      verify(() => tokens.clearSession()).called(1);
    });
  });
}
