import '../entities/organizer.dart';
import '../usecases/sync_organizer_use_case.dart';

abstract class OrganizerRepository {
  /// Guía pura: crea/obtiene el perfil organizador desde el JWT (claim "sub").
  /// El rol lo decide el backend/Keycloak (ROLE_ORGANIZER), nunca Flutter (§19).
  Future<Organizer> syncProfile(SyncOrganizerParams params);

  Future<Organizer> getProfile();
}
