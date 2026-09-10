import '../entities/auth_session.dart';
import '../repositories/authentication_repository.dart';

class RestoreSessionUseCase {
    final AuthenticationRepository _repository;

    const RestoreSessionUseCase(this._repository);

    Future<AuthSession?> call() {
        return _repository.restoreSession();
    }
}