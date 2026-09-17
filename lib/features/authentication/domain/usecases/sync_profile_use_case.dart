import '../entities/user.dart';
import '../repositories/user_repository.dart';

class SyncProfileParams {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? birthDate;

  const SyncProfileParams({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthDate,
  });
}

class SyncProfileUseCase {
  final UserRepository _repository;

  const SyncProfileUseCase(this._repository);

  Future<User> call(SyncProfileParams params) {
    return _repository.syncProfile(params);
  }
}
