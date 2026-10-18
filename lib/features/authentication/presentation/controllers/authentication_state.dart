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
  final bool isOrganizer;
  final String? errorMessage;

  const AuthenticationState({
    required this.status,
    this.session,
    this.isOrganizer = false,
    this.errorMessage,
  });

  const AuthenticationState.initial()
    : status = AuthenticationStatus.initial,
      session = null,
      isOrganizer = false,
      errorMessage = null;

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    AuthSession? session,
    bool? isOrganizer,
    String? errorMessage,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      session: session ?? this.session,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      errorMessage: errorMessage,
    );
  }
}
