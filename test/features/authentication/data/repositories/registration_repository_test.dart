import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/authentication/data/datasources/registration_remote_data_source.dart';
import 'package:frontend/features/authentication/data/repositories/registration_repository_impl.dart';
import 'package:frontend/core/errors/failtures.dart';

import '../../../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late RegistrationRepositoryImpl repository;
  setUp(() {
    adapter = FakeHttpAdapter();
    repository = RegistrationRepositoryImpl(
      RegistrationRemoteDataSource(dioWith(adapter)),
    );
  });

  test('estado remoto distingue pendiente y completo', () async {
    adapter.reply = const FakeReply(200, {
      'data': {'status': 'PENDING'},
    });
    expect(await repository.begin(), isTrue);
    expect(adapter.last.path, '/api/v1/registrations/me');
    expect(adapter.last.method, 'POST');
    adapter.reply = const FakeReply(200, {
      'data': {'status': 'COMPLETED'},
    });
    expect(await repository.begin(), isFalse);
  });

  test('estado desconocido no habilita acceso privado', () async {
    adapter.reply = const FakeReply(200, {
      'data': {'status': 'CANCELLED'},
    });
    await expectLater(repository.begin(), throwsA(isA<ServerFailure>()));
  });

  test(
    'finalizar y cancelar usan la identidad del token sin enviar ids',
    () async {
      await repository.complete();
      expect(adapter.last.path, '/api/v1/registrations/me/complete');
      expect(adapter.last.method, 'POST');
      await repository.cancel();
      expect(adapter.last.path, '/api/v1/registrations/me');
      expect(adapter.last.method, 'DELETE');
      expect(adapter.last.data, isNull);
      expect(adapter.last.queryParameters, isEmpty);
    },
  );

  test('cuenta completa protegida conserva el mensaje de conflicto', () async {
    adapter.reply = const FakeReply(409, {'message': 'Cuenta completa'});
    await expectLater(
      repository.cancel(),
      throwsA(
        isA<ConflictFailure>().having(
          (e) => e.message,
          'mensaje',
          'Cuenta completa',
        ),
      ),
    );
  });

  test('red fallida permite informar y reintentar cancelación', () async {
    adapter.reply = const FakeReply.error(DioExceptionType.connectionError);
    await expectLater(repository.cancel(), throwsA(isA<NetworkFailure>()));
    adapter.reply = const FakeReply(200);
    await repository.cancel();
    expect(adapter.requests, hasLength(2));
  });

  test('sesión expirada no confirma la eliminación', () async {
    adapter.reply = const FakeReply(401);
    await expectLater(repository.cancel(), throwsA(isA<UnauthorizedFailure>()));
  });
}
