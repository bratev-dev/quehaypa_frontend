import '../entities/auth_session.dart';
import '../repositories/authentication_repository.dart';

/// Crea la identidad en el HTML de registro de Keycloak (/registrations,
/// cliente mobile público PKCE) y guarda la sesión.
/// La password nunca toca el monolito (Guía §10/§11).
class RegisterWithKeycloakUseCase {
  final AuthenticationRepository _repository;

  const RegisterWithKeycloakUseCase(this._repository);

  Future<AuthSession> call() {
    return _repository.register();
  }
}
