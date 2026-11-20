import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/domain/repositories/organizer_repository.dart';
import '../../../authentication/domain/repositories/user_repository.dart';

/// Proyecta los datos comunes en el perfil que consume la pantalla existente.
class GetMyProfileUseCase {
  const GetMyProfileUseCase(this.users, this.organizers);

  final UserRepository users;
  final OrganizerRepository organizers;

  Future<User> call({required bool isOrganizer}) async {
    if (!isOrganizer) return users.getProfile();
    final organizer = await organizers.getProfile();
    return User(
      id: organizer.id,
      username: organizer.username,
      firstName: organizer.firstName,
      lastName: organizer.lastName,
      email: organizer.email,
      isActive: organizer.isActive,
    );
  }
}
