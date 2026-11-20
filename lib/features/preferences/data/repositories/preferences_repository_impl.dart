import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/entities/event_seed.dart';
import '../../domain/entities/interest.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../models/event_seed_model.dart';
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

  @override
  Future<List<String>> getMyPreferences() async {
    try {
      return await _remoteDataSource.getMyPreferences();
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
      throw UnknownFailure('No fue posible leer tus intereses: $e');
    }
  }

  @override
  Future<List<Interest>> getInterests() async {
    try {
      final models = await _remoteDataSource.getInterests();
      return models.map((m) => m.toEntity()).toList();
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
      throw UnknownFailure('No fue posible cargar el catálogo: $e');
    }
  }

  @override
  Future<List<EventSeed>> getFeed() async {
    try {
      final models = await _remoteDataSource.getFeed();
      return models.map((m) => m.toEntity()).toList();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const UnknownFailure(
        'No fue posible cargar el feed. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<List<EventSeed>> getEvents({String? category}) async {
    return _loadEvents(() => _remoteDataSource.getEvents(category: category));
  }

  @override
  Future<List<EventSeed>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) => _loadEvents(
    () => _remoteDataSource.getNearbyEvents(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ),
  );

  Future<List<EventSeed>> _loadEvents(
    Future<List<EventSeedModel>> Function() request,
  ) async {
    try {
      final models = await request();
      return models.map((m) => m.toEntity()).toList();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const UnknownFailure(
        'No fue posible cargar eventos. Inténtalo de nuevo.',
      );
    }
  }
}
