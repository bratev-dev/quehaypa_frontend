import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_remote_data_source.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDataSource _remoteDataSource;

  const PreferencesRepositoryImpl({required this._remoteDataSource});

  @override
  Future<List<String>> saveMyPreferences(List<String> categories) async {
    try {
      return await _remoteDataSource.saveMyPreferences(categories);
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
      throw UnknownFailure('No fue posible guardar tus intereses: $e');
    }
  }
}
