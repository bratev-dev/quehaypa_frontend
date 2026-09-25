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
}
