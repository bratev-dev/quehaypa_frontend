import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import '../models/user_model.dart';
import 'profile_api_errors.dart';

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
      throw mapProfileDioError(e);
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
      throw mapProfileDioError(e);
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

  String _toIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
