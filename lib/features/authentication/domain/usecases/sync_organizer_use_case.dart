import '../entities/organizer.dart';
import '../repositories/organizer_repository.dart';

class SyncOrganizerParams {
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String identificationDocument;

  const SyncOrganizerParams({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.identificationDocument,
  });
}

class SyncOrganizerUseCase {
  final OrganizerRepository _repository;

  const SyncOrganizerUseCase(this._repository);

  Future<Organizer> call(SyncOrganizerParams params) {
    return _repository.syncProfile(params);
  }
}
