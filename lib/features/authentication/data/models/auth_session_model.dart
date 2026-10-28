import 'dart:convert';

import '../../domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
  });
  final String accessToken;
  final String? refreshToken, idToken;

  Map<String, dynamic> _decode(String? token) {
    if (token == null) return {};
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final value = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return value is Map<String, dynamic> ? value : {};
    } on FormatException {
      return {};
    }
  }

  AuthSession toEntity() {
    final access = _decode(accessToken);
    final identity = _decode(idToken);
    String claim(String key) => identity[key] is String
        ? identity[key] as String
        : access[key] is String
        ? access[key] as String
        : '';
    final realm = access['realm_access'];
    final roles = realm is Map ? realm['roles'] : null;
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      email: claim('email'),
      username: claim('preferred_username'),
      firstName: claim('given_name'),
      lastName: claim('family_name'),
      subject: claim('sub'),
      isOrganizer: roles is List && roles.contains('ROLE_ORGANIZER'),
    );
  }
}
