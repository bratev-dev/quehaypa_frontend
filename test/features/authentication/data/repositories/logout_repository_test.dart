import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/security/token_manager.dart';
import 'package:frontend/features/authentication/data/datasources/keycloak_data_source.dart';
import 'package:frontend/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeycloakDataSource extends Mock implements KeycloakDataSource {}

class _MockTokenManager extends Mock implements TokenManager {}

void main() {
  test('elimina tokens locales aunque falle el cierre remoto', () async {
    final keycloak = _MockKeycloakDataSource();
    final tokens = _MockTokenManager();
    when(() => tokens.getIdToken()).thenAnswer((_) async => 'id-token');
    when(() => keycloak.logout('id-token'))
        .thenThrow(const AuthenticationException('fallo remoto'));
    when(() => tokens.clearSession()).thenAnswer((_) async {});

    final repository = AuthenticationRepositoryImpl(
      keycloakDataSource: keycloak,
      tokenManager: tokens,
    );

    await expectLater(
      repository.logout(),
      throwsA(isA<AuthenticationException>()),
    );
    verify(() => tokens.clearSession()).called(1);
  });
}
