import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import '../datasources/user_remote_data_source.dart';
import 'profile_failures.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  const UserRepositoryImpl({required this._remoteDataSource});

  @override
  Future<User> syncProfile(SyncProfileParams params) async {
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
  Future<User> getProfile() async {
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

  @override
  Future<User> updateProfile({
    required int id,
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    try {
      final model = await _remoteDataSource.updateProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      );
      return model.toEntity();
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible actualizar tu perfil: $e');
    }
  }
}
