import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/event_seed_model.dart';
import '../models/interest_model.dart';

/// Habla con el monolito para intereses/eventos.
/// El Bearer lo pone AuthInterceptor. Parsea el envelope ApiResponse{data}.
class PreferencesRemoteDataSource {
  final Dio _dio;

  const PreferencesRemoteDataSource({required this._dio});

  Future<List<String>> saveMyPreferences(List<String> categories) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/preferences/me',
        data: {'categories': categories},
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ServerException(
          'El servidor devolvió preferencias con formato inesperado.',
        );
      }
      return data.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<String>> getMyPreferences() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/preferences/me',
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ServerException(
          'El servidor devolvió preferencias con formato inesperado.',
        );
      }
      return data.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<InterestModel>> getInterests() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/interests',
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ServerException(
          'El servidor devolvió el catálogo con formato inesperado.',
        );
      }
      try {
        return data
            .whereType<Map<String, dynamic>>()
            .map(InterestModel.fromJson)
            .toList();
      } catch (_) {
        throw const ServerException(
          'El servidor devolvió un interés con formato inesperado.',
        );
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<EventSeedModel>> getFeed() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/events/feed/me',
      );
      return _parseEventList(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<EventSeedModel>> getEvents({String? category}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/events',
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return _parseEventList(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  List<EventSeedModel> _parseEventList(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! List) {
      throw const ServerException(
        'El servidor devolvió eventos con formato inesperado.',
      );
    }
    try {
      return data
          .whereType<Map<String, dynamic>>()
          .map(EventSeedModel.fromJson)
          .toList();
    } catch (_) {
      throw const ServerException(
        'El servidor devolvió un evento con formato inesperado.',
      );
    }
  }

  Exception _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);

    if (statusCode == 400) return ValidationException(message);
    if (statusCode == 401) {
      return const UnauthorizedException('No autorizado.');
    }
    if (statusCode == 403) {
      return const UnauthorizedException(
        'No tienes permisos para esta operación.',
      );
    }
    if (statusCode == 404) {
      return ServerException(message);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'No fue posible conectarse con el servidor. Revisa tu conexión.',
      );
    }
    return ServerException(message);
  }

  String _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Ocurrió un error inesperado en el servidor.';
  }
}
