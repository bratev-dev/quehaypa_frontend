import '../../domain/entities/auth_session.dart';

enum AuthenticationStatus {
  initial,
  loading,
  authenticated,
  registrationRequired,
  unauthenticated,
  error,
}

class AuthenticationState {
  final AuthenticationStatus status;
  final AuthSession? session;
  final String? errorMessage;

  const AuthenticationState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  const AuthenticationState.initial()
    : status = AuthenticationStatus.initial,
      session = null,
      errorMessage = null;

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    AuthSession? session,
    String? errorMessage,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }
}
