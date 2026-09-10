import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config_provider.dart';
import '../../../../core/security/security_providers.dart';
import '../../data/datasources/keycloak_data_source.dart';
import '../../data/repositories/authentication_repository_impl.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/refresh_session_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';

final keycloakDataSourceProvider = Provider<KeycloakDataSource>((ref) {
    return KeycloakDataSource(
        config: ref.read(appConfigProvider),
    );
});

final authenticationRepositoryProvider = Provider<AuthenticationRepository>((ref) {
    return AuthenticationRepositoryImpl(
        keycloakDataSource:
            ref.read(keycloakDataSourceProvider),
        tokenManager: ref.read(tokenManagerProvider),
    );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
    return LoginUseCase(
        ref.read(authenticationRepositoryProvider),
    );
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
    return RestoreSessionUseCase(
        ref.read(authenticationRepositoryProvider),
    );
});

final refreshSessionUseCaseProvider = Provider<RefreshSessionUseCase>((ref) {
    return RefreshSessionUseCase(
        ref.read(authenticationRepositoryProvider),
    );
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
    return LogoutUseCase(
        ref.read(authenticationRepositoryProvider),
    );
});