import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/plan_params.dart';
import '../models/plan_model.dart';

/// Única clase que habla con el monolito para planes.
/// El Bearer lo pone AuthInterceptor. Parsea el envelope ApiResponse{data}.
class PlanRemoteDataSource {
  final Dio _dio;

  const PlanRemoteDataSource({required this._dio});

  Future<List<PlanModel>> getMyPlans() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/plans/my-plans',
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ServerException(
          'El servidor devolvió planes con formato inesperado.',
        );
      }
      try {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PlanModel.fromJson)
            .toList();
      } catch (_) {
        throw const ServerException(
          'El servidor devolvió un plan con formato inesperado.',
        );
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<PlanModel> createPlan(CreatePlanParams params) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/plans',
        data: {
          'title': params.title,
          'description': params.description,
          if (params.meetingDate != null)
            'meetingDate': params.meetingDate!.toIso8601String(),
        },
      );
      return _parseSingleEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<PlanModel> updatePlan(UpdatePlanParams params) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/plans/${params.planId}/edit',
        data: {
          'title': params.title,
          'description': params.description,
          if (params.meetingDate != null)
            'meetingDate': params.meetingDate!.toIso8601String(),
        },
      );
      return _parseSingleEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> deletePlan(int planId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/api/v1/plans/$planId/delete');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  PlanModel _parseSingleEnvelope(Map<String, dynamic>? envelope) {
    if (envelope == null || envelope['data'] is! Map<String, dynamic>) {
      throw const ServerException(
        'El servidor devolvió una respuesta inesperada.',
      );
    }
    try {
      return PlanModel.fromJson(envelope['data'] as Map<String, dynamic>);
    } catch (_) {
      throw const ServerException(
        'El servidor devolvió un plan con formato inesperado.',
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
    if (statusCode == 409) return ConflictException(message);
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
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Ocurrió un error inesperado en el servidor.';
  }
}
