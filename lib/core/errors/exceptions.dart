class ServerException implements Exception {
  final String message;

  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// El usuario cerró o canceló el flujo de Keycloak (ej. botón atrás en la
/// pantalla de login) antes de completar la autenticación. No es un error.
class AuthenticationCancelledException implements Exception {
  const AuthenticationCancelledException();

  @override
  String toString() => 'AuthenticationCancelledException';
}

class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

class ConflictException implements Exception {
  final String message;

  const ConflictException(this.message);

  @override
  String toString() => 'ConflictException: $message';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
