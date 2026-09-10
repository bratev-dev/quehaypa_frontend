class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
  });
}
