import '../entities/auth_session.dart';

abstract class AuthenticationRepository {
  Future<AuthSession> login({String? loginHint});

  /// Crea la identidad en el HTML de registro de Keycloak (PKCE)
  /// y guarda la sesión. La password nunca toca el monolito.
  Future<AuthSession> register();

  Future<AuthSession?> restoreSession();

  Future<AuthSession> refreshSession();

  Future<void> logout();
}
