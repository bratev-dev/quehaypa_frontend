import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/security/secure_storage.dart';
import 'package:frontend/core/security/token_manager.dart';

/// JWT sin firma válida: TokenManager solo lee el claim `exp` del payload.
String _jwt(Map<String, dynamic> claims) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.firma';
}

int _epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SecureStorage', () {
    test('guarda, lee y borra los tres tokens', () async {
      final storage = SecureStorage();

      await storage.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
        idToken: 'i',
      );

      expect(await storage.getAccessToken(), 'a');
      expect(await storage.getRefreshToken(), 'r');
      expect(await storage.getIdToken(), 'i');

      await storage.clearTokens();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getIdToken(), isNull);
    });

    test('sin refresh ni id token solo guarda el access token', () async {
      final storage = SecureStorage();

      await storage.saveTokens(accessToken: 'solo-access');

      expect(await storage.getAccessToken(), 'solo-access');
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getIdToken(), isNull);
    });
  });

  group('TokenManager', () {
    late TokenManager manager;

    setUp(() => manager = TokenManager(storage: SecureStorage()));

    test('persiste registro pendiente y lo borra al cerrar sesión', () async {
      expect(await manager.isRegistrationPending(), isFalse);
      await manager.setRegistrationPending(true);
      final reopened = TokenManager(storage: SecureStorage());
      expect(await reopened.isRegistrationPending(), isTrue);
      await reopened.setRegistrationPending(false);
      expect(await manager.isRegistrationPending(), isFalse);
      await manager.setRegistrationPending(true);
      await manager.clearSession();
      expect(await reopened.isRegistrationPending(), isFalse);
    });

    test('saveTokenResponse guarda los tokens de Keycloak', () async {
      await manager.saveTokenResponse(
        TokenResponse('acc', 'ref', null, 'idt', 'Bearer', null, null),
      );

      expect(await manager.getAccessToken(), 'acc');
      expect(await manager.getRefreshToken(), 'ref');
      expect(await manager.getIdToken(), 'idt');
    });

    test('saveTokenResponse sin access token lanza excepción', () {
      expect(
        manager.saveTokenResponse(
          TokenResponse(null, 'ref', null, null, null, null, null),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('hasSession es verdadero con un token vigente', () async {
      final exp = _epoch(DateTime.now().add(const Duration(hours: 1)));
      await manager.saveTokens(accessToken: _jwt({'exp': exp}));

      expect(await manager.hasSession(), isTrue);
    });

    test(
      'hasSession es falso si el token vence en menos de 60 segundos',
      () async {
        final exp = _epoch(DateTime.now().add(const Duration(seconds: 30)));
        await manager.saveTokens(accessToken: _jwt({'exp': exp}));

        expect(await manager.hasSession(), isFalse);
      },
    );

    test('hasSession es falso sin token', () async {
      expect(await manager.hasSession(), isFalse);
    });

    test('hasSession es falso con un token que no es JWT', () async {
      await manager.saveTokens(accessToken: 'no-es-un-jwt');

      expect(await manager.hasSession(), isFalse);
    });

    test('hasSession es falso si el token no trae exp', () async {
      await manager.saveTokens(accessToken: _jwt({'sub': 'x'}));

      expect(await manager.hasSession(), isFalse);
    });

    test('hasSession es falso si el payload no es JSON válido', () async {
      await manager.saveTokens(accessToken: 'aGVhZA.bm8tanNvbg.firma');

      expect(await manager.hasSession(), isFalse);
    });

    test('clearSession borra los tokens', () async {
      await manager.saveTokens(accessToken: 'a', refreshToken: 'r');

      await manager.clearSession();

      expect(await manager.getAccessToken(), isNull);
      expect(await manager.getRefreshToken(), isNull);
    });
  });
}
