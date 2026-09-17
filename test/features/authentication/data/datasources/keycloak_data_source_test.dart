import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/config/app_config.dart';
import 'package:frontend/app/config/environment.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/authentication/data/datasources/keycloak_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterAppAuth extends Mock implements FlutterAppAuth {}

void main() {
  late MockFlutterAppAuth appAuth;
  late KeycloakDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(
      AuthorizationTokenRequest(
        'client',
        'redirect',
        issuer: 'http://issuer',
        scopes: const ['openid'],
      ),
    );
  });

  setUp(() {
    appAuth = MockFlutterAppAuth();
    dataSource = KeycloakDataSource(
      config: const AppConfig(
        environment: Environment.development,
        apiBaseUrl: 'http://api',
        keycloakIssuer: 'http://issuer/realms/test',
        keycloakClientId: 'que-hay-pa-mobile',
        keycloakRedirectUrl: 'com.quehaypa.app://oauth/callback',
        keycloakEndSessionUrl: 'http://issuer/logout',
      ),
      appAuth: appAuth,
    );
  });

  AuthorizationTokenResponse tokenResponse() => AuthorizationTokenResponse(
    'access-123',
    'refresh-123',
    null,
    'id-123',
    'Bearer',
    const ['openid'],
    null,
    null,
  );

  group('register (HTML de Keycloak)', () {
    test('usa el endpoint /registrations y retorna la sesión', () async {
      AuthorizationTokenRequest? captured;
      when(() => appAuth.authorizeAndExchangeCode(any()))
          .thenAnswer((invocation) async {
            captured =
                invocation.positionalArguments[0] as AuthorizationTokenRequest;
            return tokenResponse();
          });

      final session = await dataSource.register();

      expect(session.accessToken, 'access-123');
      expect(session.refreshToken, 'refresh-123');
      final config = captured!.serviceConfiguration!;
      expect(config.authorizationEndpoint, contains('/registrations'));
      expect(config.tokenEndpoint, contains('/token'));
    });

    test('sin access token lanza AuthenticationException', () {
      when(() => appAuth.authorizeAndExchangeCode(any())).thenAnswer(
        (_) async => AuthorizationTokenResponse(
          null,
          null,
          null,
          null,
          'Bearer',
          const ['openid'],
          null,
          null,
        ),
      );

      expect(dataSource.register(), throwsA(isA<AuthenticationException>()));
    });
  });

  group('login', () {
    test('retorna la sesión con el access token', () async {
      when(() => appAuth.authorizeAndExchangeCode(any()))
          .thenAnswer((_) async => tokenResponse());

      final session = await dataSource.login();

      expect(session.accessToken, 'access-123');
    });
  });
}
