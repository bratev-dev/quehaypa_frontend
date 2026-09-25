import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/app_error_handler.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';

void main() {
  group('AppErrorHandler.getFriendlyMessage', () {
    const conexion =
        'No pudimos conectar con el servidor de autenticación. Verifica tu conexión a internet o intenta más tarde.';
    const credenciales =
        'Correo o contraseña incorrectos. Por favor, verifica tus datos.';
    const generico = 'Ocurrió un error inesperado. Inténtalo de nuevo.';

    for (final error in [
      'discovery_failed',
      'Network Error',
      'FileNotFoundException',
      'SocketException: Failed host lookup',
      'Connection refused',
      'Connection timed out',
    ]) {
      test('"$error" -> mensaje de conexión', () {
        expect(AppErrorHandler.getFriendlyMessage(Exception(error)), conexion);
      });
    }

    test('invalid_grant -> credenciales incorrectas', () {
      expect(AppErrorHandler.getFriendlyMessage('invalid_grant'), credenciales);
    });

    test('Unauthorized (mayúsculas) -> credenciales incorrectas', () {
      expect(AppErrorHandler.getFriendlyMessage('UNAUTHORIZED'), credenciales);
    });

    test('cualquier otro error -> mensaje genérico', () {
      expect(AppErrorHandler.getFriendlyMessage(StateError('x')), generico);
    });
  });

  group('excepciones', () {
    test('toString incluye el tipo y el mensaje', () {
      expect(const ServerException('m').toString(), 'ServerException: m');
      expect(const NetworkException('m').toString(), 'NetworkException: m');
      expect(
        const UnauthorizedException('m').toString(),
        'UnauthorizedException: m',
      );
      expect(
        const AuthenticationException('m').toString(),
        'AuthenticationException: m',
      );
      expect(const StorageException('m').toString(), 'StorageException: m');
      expect(const ConflictException('m').toString(), 'ConflictException: m');
      expect(
        const ValidationException('m').toString(),
        'ValidationException: m',
      );
      expect(
        const AuthenticationCancelledException().toString(),
        'AuthenticationCancelledException',
      );
    });
  });

  group('failures', () {
    test('conservan el mensaje', () {
      final failures = <Failure>[
        const NetworkFailure('a'),
        const UnauthorizedFailure('b'),
        const AuthenticationFailure('c'),
        const ServerFailure('d'),
        const StorageFailure('e'),
        const ConflictFailure('f'),
        const ValidationFailure('g'),
        const UnknownFailure('h'),
      ];
      expect(failures.map((f) => f.message), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
      ]);
    });
  });
}
