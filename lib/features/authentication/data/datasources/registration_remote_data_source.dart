import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import 'profile_api_errors.dart';

class RegistrationRemoteDataSource {
  final Dio _dio;
  const RegistrationRemoteDataSource(this._dio);
  static const _path = '/api/v1/registrations/me';

  Future<bool> begin() async {
    try {
      final response = await _dio.post<dynamic>(_path);
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      final status = data is Map ? data['status'] : null;
      if (status == 'PENDING') return true;
      if (status == 'COMPLETED') return false;
      throw const ServerException(
        'El servidor devolvió un estado de registro inválido.',
      );
    } on DioException catch (e) {
      throw mapProfileDioError(e);
    }
  }

  Future<void> complete() => _request(complete: true);
  Future<void> cancel() => _request(complete: false);

  Future<void> _request({required bool complete}) async {
    try {
      if (complete) {
        await _dio.post<dynamic>('$_path/complete');
      } else {
        await _dio.delete<dynamic>(_path);
      }
    } on DioException catch (e) {
      throw mapProfileDioError(e);
    }
  }
}
