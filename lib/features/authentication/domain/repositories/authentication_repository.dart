import '../entities/auth_session.dart';

abstract class AuthenticationRepository {
  Future<AuthSession> login();

  Future<AuthSession?> restoreSession();

  Future<AuthSession> refreshSession();

  Future<void> logout();
}
