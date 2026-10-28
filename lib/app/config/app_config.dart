import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'environment.dart';

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String keycloakIssuer;
  final String keycloakClientId;
  final String keycloakRedirectUrl;
  final String keycloakEndSessionUrl;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.keycloakIssuer,
    required this.keycloakClientId,
    required this.keycloakRedirectUrl,
    required this.keycloakEndSessionUrl,
  });

  static const _buildApi = String.fromEnvironment('API_BASE_URL');
  static const _buildIssuer = String.fromEnvironment('KEYCLOAK_ISSUER_URL');
  static final String _api = _buildApi.isNotEmpty
      ? _buildApi
      : dotenv.env['API_BASE_URL'] ?? '';
  static final String _issuer = _buildIssuer.isNotEmpty
      ? _buildIssuer
      : dotenv.env['KEYCLOAK_ISSUER_URL'] ?? '';

  static final development = AppConfig(
    environment: Environment.development,
    apiBaseUrl: _api,
    keycloakIssuer: _issuer,
    keycloakClientId: 'que-hay-pa-mobile',
    keycloakRedirectUrl: 'com.quehaypa.app://oauth/callback',
    keycloakEndSessionUrl: '$_issuer/protocol/openid-connect/logout',
  );

  static AppConfig fromEnvironment() {
    if (_buildApi.isEmpty) return development;
    return AppConfig(
      environment: Environment.production,
      apiBaseUrl: _api,
      keycloakIssuer: _issuer,
      keycloakClientId: development.keycloakClientId,
      keycloakRedirectUrl: development.keycloakRedirectUrl,
      keycloakEndSessionUrl: development.keycloakEndSessionUrl,
    );
  }
}
