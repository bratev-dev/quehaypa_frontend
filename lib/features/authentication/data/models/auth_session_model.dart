import '../../domain/entities/auth_session.dart';

class AuthSessionModel {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  const AuthSessionModel({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
    );
  }
}
