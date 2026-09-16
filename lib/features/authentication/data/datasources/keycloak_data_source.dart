import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_session_model.dart';

class KeycloakDataSource {
  final FlutterAppAuth _appAuth;
  final AppConfig _config;

  const KeycloakDataSource({required this._config, FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? const FlutterAppAuth();

  Future<AuthSessionModel> login({String? loginHint}) async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _config.keycloakClientId,
          _config.keycloakRedirectUrl,
          issuer: _config.keycloakIssuer,
          scopes: const ['openid', 'profile', 'email'],
          allowInsecureConnections: true,
          loginHint: (loginHint != null && loginHint.isNotEmpty)
              ? loginHint
              : null,
        ),
      );

      final accessToken = result.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthenticationException(
          'Keycloak no devolvio un Access Token.',
        );
      }

      return AuthSessionModel(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    } on AuthenticationException {
      rethrow;
    } on PlatformException catch (e) {
      if (_isUserCancellation(e)) {
        throw const AuthenticationCancelledException();
      }
      throw AuthenticationException(
        'No fue posible iniciar sesión con Keycloak: $e',
      );
    } catch (e) {
      throw AuthenticationException(
        'No fue posible iniciar sesión con Keycloak: $e',
      );
    }
  }

  /// Abre el HTML de registro de Keycloak (no el login).
  /// La password se crea allá (mobile público, sin directAccess).
  /// Requiere `User registration ON` en el realm vivo.
  Future<AuthSessionModel> register() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _config.keycloakClientId,
          _config.keycloakRedirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint:
                '${_config.keycloakIssuer}/protocol/openid-connect/registrations',
            tokenEndpoint:
                '${_config.keycloakIssuer}/protocol/openid-connect/token',
          ),
          scopes: const ['openid', 'profile', 'email'],
          allowInsecureConnections: true,
        ),
      );

      final accessToken = result.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthenticationException(
          'Keycloak no devolvio un Access Token.',
        );
      }

      return AuthSessionModel(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw AuthenticationException(
        'No fue posible registrarse en Keycloak: $e',
      );
    }
  }

  /// `flutter_appauth` reporta la cancelación del usuario de forma distinta
  /// por plataforma: Android emite el mensaje "User cancelled flow" en el
  /// código `authorize_and_exchange_code_failed`; iOS/AppAuth-iOS usa el
  /// código `-3` (`OIDErrorCodeUserCanceledAuthorizationFlow`) en su detalle.
  bool _isUserCancellation(PlatformException e) {
    final message = (e.message ?? '').toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';
    return message.contains('cancel') ||
        details.contains('cancel') ||
        details.contains('-3');
  }

  Future<AuthSessionModel> refreshSession(String refreshToken) async {
    try {
      final result = await _appAuth.token(
        TokenRequest(
          _config.keycloakClientId,
          _config.keycloakRedirectUrl,
          issuer: _config.keycloakIssuer,
          refreshToken: refreshToken,
          scopes: const ['openid', 'profile', 'email'],
          allowInsecureConnections: true,
        ),
      );

      final accessToken = result.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthenticationException(
          'Keycloak no devolvio un nuevo Access Token.',
        );
      }

      return AuthSessionModel(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw AuthenticationException(
        'No fue posible renovar la sesion con Keycloak: $e',
      );
    }
  }

  Future<void> logout(String idToken) async {
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: _config.keycloakRedirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint:
                '${_config.keycloakIssuer}/protocol/openid-connect/auth',
            tokenEndpoint:
                '${_config.keycloakIssuer}/protocol/openid-connect/token',
            endSessionEndpoint: _config.keycloakEndSessionUrl,
          ),
          allowInsecureConnections: true,
        ),
      );
    } catch (e) {
      throw AuthenticationException(
        'No fue posible cerrar la sesion en Keycloak: $e',
      );
    }
  }
}

