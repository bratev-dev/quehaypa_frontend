import 'dart:convert';

class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  /// Datos de la identidad para el formulario; no se usan para autorizar roles.
  String get email => _claim('email');
  String get username => _claim('preferred_username');
  String get firstName => _claim('given_name');
  String get lastName => _claim('family_name');

  /// Identificador estable de la cuenta en Keycloak: no cambia ni se reutiliza.
  String get subject => _claim('sub');

  String _claim(String name) {
    for (final token in [idToken, accessToken]) {
      if (token == null) continue;
      try {
        final parts = token.split('.');
        if (parts.length != 3) continue;
        final claims = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (claims is Map<String, dynamic> && claims[name] is String) {
          return claims[name] as String;
        }
      } on FormatException {
        // Un token sin estos datos no aporta valores al formulario.
      }
    }
    return '';
  }
}
