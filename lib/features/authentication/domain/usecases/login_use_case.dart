import '../entities/auth_session.dart';
import '../repositories/authentication_repository.dart';

class LoginUseCase {
  final AuthenticationRepository _repository;

  const LoginUseCase(this._repository);

  Future<AuthSession> call() {
    return _repository.login();
  }
}
