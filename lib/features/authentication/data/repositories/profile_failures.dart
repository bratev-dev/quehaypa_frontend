import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';

/// Traduce las excepciones de los datasources de perfil (usuario regular y
/// organizador) a failures del dominio.
///
/// [includeInputErrors] mapea 409 y 400 a sus failures propios; si es false
/// (consultas que no envían datos), terminan como [UnknownFailure].
Failure toProfileFailure(
  Object error, {
  required String unauthorizedMessage,
  required String unknownMessage,
  bool includeInputErrors = true,
}) {
  if (includeInputErrors) {
    if (error is ConflictException) return ConflictFailure(error.message);
    if (error is ValidationException) return ValidationFailure(error.message);
  }

  return switch (error) {
    UnauthorizedException() => UnauthorizedFailure(unauthorizedMessage),
    NetworkException(:final message) => NetworkFailure(message),
    ServerException(:final message) => ServerFailure(message),
    _ => UnknownFailure('$unknownMessage: $error'),
  };
}
