import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/token_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/keycloak_data_source.dart';
import '../models/auth_session_model.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
    final KeycloakDataSource _keycloakDataSource;
    final TokenManager _tokenManager;

    const AuthenticationRepositoryImpl({
        required this._keycloakDataSource,
        required this._tokenManager,
    });

    @override
    Future<AuthSession> login() async {
        try {
            final model = await _keycloakDataSource.login();

            await _tokenManager.saveTokens(
                accessToken: model.accessToken,
                refreshToken: model.refreshToken,
                idToken: model.idToken,
            );

            return model.toEntity();
        } on AuthenticationException {
            rethrow;
        } catch (e) {
            throw AuthenticationException(
                'No fue posible guardar la sesion despues del inicio de sesion: $e',
            );
        }
    }

    @override
    Future<AuthSession?> restoreSession() async {
        try {
            final accessToken =
                await _tokenManager.getAccessToken();

            if (accessToken == null || accessToken.isEmpty) {
                return null;
            }

            final hasValidSession = await _tokenManager.hasSession();

            if (hasValidSession) {
                final refreshToken = await _tokenManager.getRefreshToken();

                final idToken = await _tokenManager.getIdToken();

                return AuthSessionModel(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    idToken: idToken,
                ).toEntity();
            }

            final refreshToken = await _tokenManager.getRefreshToken();

            if (refreshToken == null || refreshToken.isEmpty) {
                await _tokenManager.clearSession();
                return null;
            }

            try {
                return await refreshSession();
            } on AuthenticationException {
                await _tokenManager.clearSession();
                return null;
            }
        } catch (e) {
            if (e is AuthenticationException) {
                rethrow;
            }

            throw StorageException(
                'No fue posible restaurar la sesion almacenada: $e',
            );
        }
    }

    @override
    Future<AuthSession> refreshSession() async {
        final refreshToken = await _tokenManager.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
            throw const AuthenticationException(
                'No existe un Refresh Token disponible.',
            );
        }

        try {
            final model = await _keycloakDataSource.refreshSession(
                refreshToken,
            );

            await _tokenManager.saveTokens(
                accessToken: model.accessToken,
                refreshToken: model.refreshToken,
                idToken: model.idToken,
            );

            return model.toEntity();
        } on AuthenticationException {
            rethrow;
        } catch (e) {
            throw AuthenticationException(
                'No fue posible renovar la sesion: $e',
            );
        }
    }

    @override
    Future<void> logout() async {
        final idToken = await _tokenManager.getIdToken();

        try {
            if (idToken != null && idToken.isNotEmpty) {
                await _keycloakDataSource.logout(idToken);
            }
        } finally {
            await _tokenManager.clearSession();
        }
    }
}