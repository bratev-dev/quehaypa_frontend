import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/security_providers.dart';
import '../../../../core/security/session_events_provider.dart';
import '../../data/datasources/organizer_remote_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/organizer_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/session_invalidator_impl.dart';
import '../../data/services/session_refresher_impl.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import 'authentication_providers.dart';

/// Dio centralizado con Bearer automático (AuthInterceptor).
final dioProvider = Provider<Dio>((ref) {
  final refresher = SessionRefresherImpl(
    refreshSessionUseCase: ref.read(refreshSessionUseCaseProvider),
  );
  final invalidator = SessionInvalidatorImpl(
    tokenManager: ref.read(tokenManagerProvider),
    sessionEvents: ref.read(sessionEventsProvider),
  );

  return DioClient(
    config: ref.read(appConfigProvider),
    tokenManager: ref.read(tokenManagerProvider),
    sessionRefresher: refresher,
    sessionInvalidator: invalidator,
  ).dio;
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(dio: ref.read(dioProvider));
});

final organizerRemoteDataSourceProvider =
    Provider<OrganizerRemoteDataSource>((ref) {
      return OrganizerRemoteDataSource(dio: ref.read(dioProvider));
    });

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
  );
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return OrganizerRepositoryImpl(
    remoteDataSource: ref.read(organizerRemoteDataSourceProvider),
  );
});

final syncProfileUseCaseProvider = Provider<SyncProfileUseCase>((ref) {
  return SyncProfileUseCase(ref.read(userRepositoryProvider));
});

final syncOrganizerUseCaseProvider = Provider<SyncOrganizerUseCase>((ref) {
  return SyncOrganizerUseCase(ref.read(organizerRepositoryProvider));
});
