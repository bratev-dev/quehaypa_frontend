import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/plan_params.dart';
import '../models/plan_model.dart';
import '../../../preferences/data/models/event_seed_model.dart';

/// Única clase que habla con el monolito para planes.
/// El Bearer lo pone AuthInterceptor. Parsea el envelope ApiResponse{data}.
class PlanRemoteDataSource {
  final Dio dio;

  const PlanRemoteDataSource({required this.dio});

  Future<List<PlanModel>> getMyPlans() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
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
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/plans',
        data: {
          'title': params.title,
          'description': params.description,
          if (params.meetingDate != null)
            'meetingDate': _toBackendDate(params.meetingDate!),
        },
      );
      return _parseSingleEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<PlanModel> updatePlan(UpdatePlanParams params) async {
    try {
      final response = await dio.put<Map<String, dynamic>>(
        '/api/v1/plans/${params.planId}/edit',
        data: {
          'title': params.title,
          'description': params.description,
          'meetingDate': params.meetingDate == null
              ? null
              : _toBackendDate(params.meetingDate!),
        },
      );
      return _parseSingleEnvelope(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> deletePlan(int planId) async {
    try {
      await dio.delete<Map<String, dynamic>>('/api/v1/plans/$planId/delete');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<EventSeedModel> addEvent(int planId, int eventId) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/plans/$planId/items',
        data: {'eventId': eventId},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ServerException('El servidor devolvió un evento inválido.');
      }
      return EventSeedModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on FormatException {
      throw const ServerException('El servidor devolvió un evento inválido.');
    }
  }

  Future<List<EventSeedModel>> getPlanEvents(int planId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/plans/$planId/items',
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const ServerException('El servidor devolvió eventos inválidos.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(EventSeedModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on FormatException {
      throw const ServerException('El servidor devolvió eventos inválidos.');
    }
  }

  Future<void> removeEvent(int planId, int eventId) async {
    try {
      await dio.delete<Map<String, dynamic>>(
        '/api/v1/plans/$planId/items/$eventId',
      );
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
        statusCode: 403,
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

  /// El back usa LocalDateTime sin zona (yyyy-MM-dd'T'HH:mm:ss).
  /// toIso8601String() con milis/Z rompe a Jackson -> 400/500.
  String _toBackendDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }
}
