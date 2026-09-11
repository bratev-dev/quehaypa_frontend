import 'package:flutter_appauth/flutter_appauth.dart';

class AuthService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  static const String _clientId = 'que-hay-pa-mobile';

  static const String _redirectUrl = 'com.quehaypa.app://oauth/callback';

  static const String _issuer = 'http://localhost:9090/realms/que-hay-pa-dev';

  Future<AuthorizationTokenResponse> login() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        issuer: _issuer,
        scopes: const ['openid', 'profile', 'email'],
        allowInsecureConnections: true,
      ),
    );

    return result;
  }

  Future<TokenResponse> refreshToken(String refreshToken) async {
    final result = await _appAuth.token(
      TokenRequest(
        _clientId,
        _redirectUrl,
        issuer: _issuer,
        refreshToken: refreshToken,
        scopes: const ['openid', 'profile', 'email'],
        allowInsecureConnections: true,
      ),
    );

    return result;
  }

  Future<void> logout({required String idToken}) async {
    await _appAuth.endSession(
      EndSessionRequest(
        idTokenHint: idToken,
        postLogoutRedirectUrl: _redirectUrl,
        issuer: _issuer,
        allowInsecureConnections: true,
      ),
    );
  }
}
