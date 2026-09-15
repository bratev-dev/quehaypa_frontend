import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/entities/organizer.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../datasources/organizer_remote_data_source.dart';

class OrganizerRepositoryImpl implements OrganizerRepository {
  final OrganizerRemoteDataSource _remoteDataSource;

  const OrganizerRepositoryImpl({required this._remoteDataSource});

  @override
  Future<Organizer> syncProfile(SyncOrganizerParams params) async {
    try {
      final model = await _remoteDataSource.syncProfile(params);

      return model.toEntity();
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'No fue posible validar tu sesión con Keycloak. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible sincronizar tu perfil: $e');
    }
  }

  @override
  Future<Organizer> getProfile() async {
    try {
      final model = await _remoteDataSource.getProfile();

      return model.toEntity();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible obtener tu perfil: $e');
    }
  }
}
