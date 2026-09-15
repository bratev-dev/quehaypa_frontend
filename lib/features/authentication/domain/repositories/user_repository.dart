import '../entities/user.dart';
import '../usecases/sync_profile_use_case.dart';

abstract class UserRepository {
  /// Guía pura: crea/obtiene el perfil desde el JWT (claim "sub"), sin password.
  Future<User> syncProfile(SyncProfileParams params);

  /// Perfil actual (quién está logeado). Bearer vía AuthInterceptor.
  Future<User> getProfile();
}
