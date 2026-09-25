import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/data/datasources/organizer_remote_data_source.dart';
import 'package:frontend/features/authentication/data/datasources/user_remote_data_source.dart';
import 'package:frontend/features/authentication/data/repositories/organizer_repository_impl.dart';
import 'package:frontend/features/authentication/data/repositories/profile_failures.dart';
import 'package:frontend/features/authentication/data/repositories/user_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRemote extends Mock implements UserRemoteDataSource {}

class _MockOrganizerRemote extends Mock implements OrganizerRemoteDataSource {}

void main() {
  group('toProfileFailure', () {
    Failure map(Object error, {bool includeInputErrors = true}) =>
        toProfileFailure(
          error,
          unauthorizedMessage: 'sesión',
          unknownMessage: 'desconocido',
          includeInputErrors: includeInputErrors,
        );

    test('traduce cada excepción de datos a su failure', () {
      expect(map(const ConflictException('dup')), isA<ConflictFailure>());
      expect(map(const ValidationException('x')), isA<ValidationFailure>());
      expect(
        map(const UnauthorizedException('x')),
        isA<UnauthorizedFailure>().having(
          (f) => f.message,
          'message',
          'sesión',
        ),
      );
      expect(
        map(const NetworkException('red')),
        isA<NetworkFailure>().having((f) => f.message, 'message', 'red'),
      );
      expect(
        map(const ServerException('caído')),
        isA<ServerFailure>().having((f) => f.message, 'message', 'caído'),
      );
      expect(
        map(StateError('raro')),
        isA<UnknownFailure>().having(
          (f) => f.message,
          'message',
          startsWith('desconocido: '),
        ),
      );
    });

    test('sin errores de entrada, 409 y 400 terminan como desconocidos', () {
      expect(
        map(const ConflictException('dup'), includeInputErrors: false),
        isA<UnknownFailure>(),
      );
      expect(
        map(const ValidationException('x'), includeInputErrors: false),
        isA<UnknownFailure>(),
      );
    });
  });

  group('getProfile de los repositorios de perfil', () {
    final casos = <String, (Exception, Matcher)>{
      'UnauthorizedException -> UnauthorizedFailure': (
        const UnauthorizedException('x'),
        isA<UnauthorizedFailure>().having(
          (f) => f.message,
          'message',
          'Sesión inválida. Inicia sesión de nuevo.',
        ),
      ),
      'NetworkException -> NetworkFailure': (
        const NetworkException('x'),
        isA<NetworkFailure>(),
      ),
      'ServerException -> ServerFailure': (
        const ServerException('x'),
        isA<ServerFailure>(),
      ),
      'otra excepción -> UnknownFailure': (
        const FormatException('x'),
        isA<UnknownFailure>(),
      ),
    };

    casos.forEach((nombre, caso) {
      test('usuario regular: $nombre', () {
        final remote = _MockUserRemote();
        when(() => remote.getProfile()).thenThrow(caso.$1);

        expect(
          UserRepositoryImpl(remoteDataSource: remote).getProfile(),
          throwsA(caso.$2),
        );
      });

      test('organizador: $nombre', () {
        final remote = _MockOrganizerRemote();
        when(() => remote.getProfile()).thenThrow(caso.$1);

        expect(
          OrganizerRepositoryImpl(remoteDataSource: remote).getProfile(),
          throwsA(caso.$2),
        );
      });
    });
  });
}
