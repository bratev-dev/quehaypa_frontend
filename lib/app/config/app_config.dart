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

  // Host donde corren la API y Keycloak. En emulador o escritorio basta
  // 'localhost'; desde un dispositivo fisico hay que pasar la IP LAN del PC:
  //   flutter run --dart-define=BACKEND_HOST=192.168.1.19
  static const _host = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: 'localhost',
  );

  static const _realm = 'http://$_host:9090/realms/que-hay-pa-dev';

  static const development = AppConfig(
    environment: Environment.development,
    apiBaseUrl: 'http://$_host:8080',
    keycloakIssuer: _realm,
    keycloakClientId: 'que-hay-pa-mobile',
    keycloakRedirectUrl:
        'com.quehaypa.app://oauth/callback',
    keycloakEndSessionUrl:
        '$_realm/protocol/openid-connect/logout',
  );
}
