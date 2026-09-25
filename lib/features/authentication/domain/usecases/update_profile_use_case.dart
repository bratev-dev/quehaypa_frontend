import '../entities/user.dart';
import '../repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository repository;

  const UpdateProfileUseCase(this.repository);

  Future<User> call({
    required int id,
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) => repository.updateProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
  );
}
