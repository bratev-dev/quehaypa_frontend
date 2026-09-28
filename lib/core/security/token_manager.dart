import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';

import 'secure_storage.dart';

class TokenManager {
  final SecureStorage _storage;

  TokenManager({SecureStorage? storage})
    : _storage = storage ?? SecureStorage();

  Future<void> saveTokenResponse(TokenResponse response) async {
    final accessToken = response.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Keycloak no devolvió un Access Token');
    }

    await saveTokens(
      accessToken: accessToken,
      refreshToken: response.refreshToken,
      idToken: response.idToken,
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return _storage.getRefreshToken();
  }

  Future<String?> getIdToken() async {
    return _storage.getIdToken();
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    return !_isExpired(accessToken);
  }

  bool _isExpired(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = base64Url.normalize(parts[1]);

      final decoded = utf8.decode(base64Url.decode(payload));

      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = claims['exp'];

      if (exp is! num) {
        return true;
      }

      final expiration = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
      );

      final now = DateTime.now();

      return now.isAfter(expiration.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return true;
    }
  }

  Future<void> clearSession() async {
    await _storage.clearTokens();
  }

  Future<void> setRegistrationPending(bool pending) =>
      _storage.setRegistrationPending(pending);

  Future<bool> isRegistrationPending() => _storage.isRegistrationPending();
}
