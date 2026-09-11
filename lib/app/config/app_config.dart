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

  static const development = AppConfig(
    environment: Environment.development,
    apiBaseUrl: 'https://quehaypa-backend-production.up.railway.app',
    keycloakIssuer: 'https://keycloak-production-58e17.up.railway.app/realms/que-hay-pa-dev',
    keycloakClientId: 'que-hay-pa-mobile',
    keycloakRedirectUrl: 'com.quehaypa.app://oauth/callback',
    keycloakEndSessionUrl: 'https://keycloak-production-58e17.up.railway.app/realms/que-hay-pa-dev/protocol/openid-connect/logout',
  );

  static const _prodApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _prodKeycloakIssuer = String.fromEnvironment(
    'KEYCLOAK_ISSUER_URL',
  );

  static const production = AppConfig(
    environment: Environment.production,
    apiBaseUrl: _prodApiBaseUrl,
    keycloakIssuer: _prodKeycloakIssuer,
    keycloakClientId: 'que-hay-pa-mobile',
    keycloakRedirectUrl: 'com.quehaypa.app://oauth/callback',
    keycloakEndSessionUrl:
        '$_prodKeycloakIssuer/protocol/openid-connect/logout',
  );

  static AppConfig fromEnvironment() {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' ? production : development;
  }
}