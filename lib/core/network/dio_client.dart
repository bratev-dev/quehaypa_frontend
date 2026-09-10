import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../security/session_refresher.dart';
import '../security/session_invalidator.dart';
import '../security/token_manager.dart';
import 'auth_interceptor.dart';

class DioClient {
    final Dio dio;

    DioClient({
        required AppConfig config,
        required TokenManager tokenManager,
        required SessionRefresher sessionRefresher,
        required SessionInvalidator sessionInvalidator,
    }) : dio = Dio(
            BaseOptions(
                baseUrl: config.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                },
            ),
            ) {
        dio.interceptors.add(
        AuthInterceptor(
            dio: dio,
            tokenManager: tokenManager,
            sessionRefresher: sessionRefresher,
            sessionInvalidator: sessionInvalidator,
        ),
        );
    }
}