import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  final Dio _dio;

  const UserRemoteDataSource({required this._dio});

  /// Guía pura: el Bearer lo pone AuthInterceptor. Sin password en body.
  Future<UserModel> syncProfile(SyncProfileParams params) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/regular-users/sync',
        data: {
          'username': params.username,
          'firstName': params.firstName,
          'lastName': params.lastName,
          'email': params.email,
          if (params.birthDate != null)
            'birthDate': _toIsoDate(params.birthDate!),
        },
      );

      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Perfil actual (quién está logeado). Bearer vía AuthInterceptor.
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/regular-users/me',
      );

      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<UserModel> updateProfile({
    required int id,
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/regular-users/$id',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          if (birthDate != null) 'birthDate': _toIsoDate(birthDate),
        },
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  UserModel _parseEnvelope(Map<String, dynamic>? envelope) {
    if (envelope == null || envelope['data'] is! Map<String, dynamic>) {
      throw const ServerException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }

    try {
      return UserModel.fromJson(envelope['data'] as Map<String, dynamic>);
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

  String _toIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
