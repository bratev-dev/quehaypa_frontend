import '../entities/auth_session.dart';
import '../repositories/authentication_repository.dart';

class RefreshSessionUseCase {
    final AuthenticationRepository _repository;

    const RefreshSessionUseCase(this._repository);

    Future<AuthSession> call() {
        return _repository.refreshSession();
    }
}