import 'package:dio/dio.dart';

import '../security/session_refresher.dart';
import '../security/session_invalidator.dart';
import '../security/token_manager.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenManager _tokenManager;
  final SessionRefresher _sessionRefresher;
  final SessionInvalidator _sessionInvalidator;

  Future<String?>? _refreshingToken;

  AuthInterceptor({
    required this._dio,
    required this._tokenManager,
    required this._sessionRefresher,
    required this._sessionInvalidator,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenManager.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;

    if (request.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    request.extra['retried'] = true;

    try {
      final newAccessToken = await _getRefreshedToken();

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _sessionInvalidator.invalidateSession();
        handler.next(err);
        return;
      }

      request.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await _retryRequest(request);

      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _sessionInvalidator.invalidateSession();
      }
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions request) {
    final data = request.data;
    final retry = data is FormData
        ? request.copyWith(data: data.clone())
        : request;
    return _dio.fetch<dynamic>(retry);
  }

  Future<String?> _getRefreshedToken() {
    final refreshingToken = _refreshingToken;

    if (refreshingToken != null) {
      return refreshingToken;
    }

    final refreshFuture = _refreshAccessToken();

    _refreshingToken = refreshFuture;

    refreshFuture.whenComplete(() {
      _refreshingToken = null;
    });

    return refreshFuture;
  }

  Future<String?> _refreshAccessToken() async {
    try {
      return await _sessionRefresher.refreshAccessToken();
    } catch (_) {
      return null;
    }
  }
}
