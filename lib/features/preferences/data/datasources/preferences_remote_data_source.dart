import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';

/// Habla con PUT /api/v1/preferences/me. Bearer vía AuthInterceptor.
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

  Exception _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);

    if (statusCode == 400) return ValidationException(message);
    if (statusCode == 401) {
      return const UnauthorizedException('No autorizado.');
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
