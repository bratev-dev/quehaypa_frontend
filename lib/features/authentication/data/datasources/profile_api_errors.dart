import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';

/// Traduce un error HTTP de los endpoints de perfil (usuario regular y
/// organizador) a la excepción de datos que esperan los repositorios.
Exception mapProfileDioError(DioException e) {
  final statusCode = e.response?.statusCode;
  final message = extractServerMessage(e.response?.data);

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
    return const NetworkException(
      'No fue posible conectarse con el servidor. Revisa tu conexión.',
    );
  }

  return ServerException(message);
}

/// Mensaje legible del cuerpo de error del backend (`ApiResponse.message`,
/// lista `errors` o `error`), o un texto genérico si no trae ninguno.
String extractServerMessage(dynamic data) {
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
