/// Identidad ya interpretada por Data; el dominio no decodifica tokens ni JSON.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.email = '',
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.subject = '',
    this.isOrganizer = false,
  });
  final String accessToken;
  final String? refreshToken, idToken;
  final String email, username, firstName, lastName, subject;

  /// Solo orienta la navegación; el backend valida los permisos del JWT.
  final bool isOrganizer;
}
