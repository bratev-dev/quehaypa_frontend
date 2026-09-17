import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../models/organizer_model.dart';

class OrganizerRemoteDataSource {
  final Dio _dio;

  const OrganizerRemoteDataSource({required this._dio});

  /// Guía pura: el Bearer lo pone AuthInterceptor. Sin password en body.
  /// El rol lo asigna el backend en Keycloak (ROLE_ORGANIZER), nunca Flutter.
  Future<OrganizerModel> syncProfile(SyncOrganizerParams params) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/organizers/sync',
        data: {
          'username': params.username,
          'firstName': params.firstName,
          'lastName': params.lastName,
          'email': params.email,
          'identificationDocument': params.identificationDocument,
        },
      );

      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<OrganizerModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/organizers/me',
      );

      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  OrganizerModel _parseEnvelope(Map<String, dynamic>? envelope) {
    if (envelope == null || envelope['data'] is! Map<String, dynamic>) {
      throw const ServerException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }

    try {
      return OrganizerModel.fromJson(envelope['data'] as Map<String, dynamic>);
    } catch (_) {
      throw const ServerException(
        'El servidor devolvió un perfil con formato inesperado.',
      );
    }
  }

  Exception _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);

    if (statusCode == 409) {
      return ConflictException(message);
    }

    if (statusCode == 400) {
      return ValidationException(message);
    }

    if (statusCode == 401) {
      return const UnauthorizedException('No autorizado.');
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(
        'No fue posible conectarse con el servidor. Revisa tu conexión.',
      );
    }

    return ServerException(message);
  }

  String _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('; ');
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return 'Ocurrió un error inesperado en el servidor.';
  }
}
