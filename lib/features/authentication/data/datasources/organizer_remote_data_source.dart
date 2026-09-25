import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../models/organizer_model.dart';
import 'profile_api_errors.dart';

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
      throw mapProfileDioError(e);
    }
  }

  Future<OrganizerModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/organizers/me',
      );

      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw mapProfileDioError(e);
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
}
