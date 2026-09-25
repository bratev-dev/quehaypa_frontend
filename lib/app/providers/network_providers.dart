import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/security/security_providers.dart';
import '../config/app_config_provider.dart';
import 'session_invalidator_providers.dart';
import 'session_providers.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.read(appConfigProvider);
  final tokenManager = ref.read(tokenManagerProvider);
  final sessionRefresher = ref.read(sessionRefresherProvider);
  final sessionInvalidator = ref.read(sessionInvalidatorProvider);

  return DioClient(
    config: config,
    tokenManager: tokenManager,
    sessionRefresher: sessionRefresher,
    sessionInvalidator: sessionInvalidator,
  );
});

/// Dio centralizado con Bearer automático (AuthInterceptor).
/// Guía §8/§12: toda Feature debe tomar el Dio de aquí, nunca crearlo
/// ni importarlo desde otra Feature.
final dioProvider = Provider<Dio>((ref) {
  return ref.read(dioClientProvider).dio;
});
