import '../repositories/authentication_repository.dart';

class LogoutUseCase {
  final AuthenticationRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> call() {
    return _repository.logout();
  }
}
