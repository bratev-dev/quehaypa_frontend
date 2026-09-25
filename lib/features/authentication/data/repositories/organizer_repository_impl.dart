import '../../domain/entities/organizer.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../datasources/organizer_remote_data_source.dart';
import 'profile_failures.dart';

class OrganizerRepositoryImpl implements OrganizerRepository {
  final OrganizerRemoteDataSource _remoteDataSource;

  const OrganizerRepositoryImpl({required this._remoteDataSource});

  @override
  Future<Organizer> syncProfile(SyncOrganizerParams params) async {
    try {
      final model = await _remoteDataSource.syncProfile(params);

      return model.toEntity();
    } catch (e) {
      throw toProfileFailure(
        e,
        unauthorizedMessage: 'No fue posible validar tu sesión con Keycloak. Inicia sesión de nuevo.',
        unknownMessage: 'No fue posible sincronizar tu perfil',
      );
    }
  }

  @override
  Future<Organizer> getProfile() async {
    try {
      final model = await _remoteDataSource.getProfile();

      return model.toEntity();
    } catch (e) {
      throw toProfileFailure(
        e,
        unauthorizedMessage: 'Sesión inválida. Inicia sesión de nuevo.',
        unknownMessage: 'No fue posible obtener tu perfil',
        includeInputErrors: false,
      );
    }
  }
}
