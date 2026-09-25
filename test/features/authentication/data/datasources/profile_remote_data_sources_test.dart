import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/authentication/data/datasources/organizer_remote_data_source.dart';
import 'package:frontend/features/authentication/data/datasources/user_remote_data_source.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';

import '../../../../helpers/fake_http_adapter.dart';

const _user = {
  'id': 7,
  'username': 'ana.ruiz',
  'firstName': 'Ana',
  'lastName': 'Ruiz',
  'email': 'ana@test.com',
  'birthDate': '1998-02-15',
  'isActive': true,
};

const _organizer = {
  'id': 9,
  'username': 'org.cauca',
  'firstName': 'Org',
  'lastName': 'Cauca',
  'email': 'org@test.com',
  'identificationDocument': '1061000000',
  'isActive': true,
};

void main() {
  late FakeHttpAdapter adapter;

  setUp(() => adapter = FakeHttpAdapter());

  group('UserRemoteDataSource', () {
    late UserRemoteDataSource dataSource;

    setUp(() => dataSource = UserRemoteDataSource(dio: dioWith(adapter)));

    test('syncProfile envía POST /regular-users/sync con la fecha ISO y parsea el perfil', () async {
      adapter.reply = const FakeReply(200, {'data': _user});

      final user = await dataSource.syncProfile(
        SyncProfileParams(
          username: 'ana.ruiz',
          firstName: 'Ana',
          lastName: 'Ruiz',
          email: 'ana@test.com',
          birthDate: DateTime(1998, 2, 5),
        ),
      );

      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/api/v1/regular-users/sync');
      expect(adapter.last.data, containsPair('birthDate', '1998-02-05'));
      expect(user.id, 7);
      expect(user.email, 'ana@test.com');
    });

    test('syncProfile sin fecha de nacimiento no envía birthDate', () async {
      adapter.reply = const FakeReply(200, {'data': _user});

      await dataSource.syncProfile(
        const SyncProfileParams(
          username: 'ana.ruiz',
          firstName: 'Ana',
          lastName: 'Ruiz',
          email: 'ana@test.com',
        ),
      );

      expect((adapter.last.data as Map).containsKey('birthDate'), isFalse);
    });

    test('getProfile hace GET /regular-users/me', () async {
      adapter.reply = const FakeReply(200, {'data': _user});

      final user = await dataSource.getProfile();

      expect(adapter.last.method, 'GET');
      expect(adapter.last.path, '/api/v1/regular-users/me');
      expect(user.username, 'ana.ruiz');
    });

    test('respuesta sin data lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {'message': 'ok'});

      expect(dataSource.getProfile(), throwsA(isA<ServerException>()));
    });

    test('perfil sin id lanza ServerException de formato', () async {
      adapter.reply = const FakeReply(200, {
        'data': {'username': 'sin.id'},
      });

      expect(
        dataSource.getProfile(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('formato inesperado'),
          ),
        ),
      );
    });

    test(
      '409 se convierte en ConflictException con el mensaje del servidor',
      () async {
        adapter.reply = const FakeReply(409, {
          'message': 'Correo ya registrado',
        });

        expect(
          dataSource.getProfile(),
          throwsA(
            isA<ConflictException>().having(
              (e) => e.message,
              'message',
              'Correo ya registrado',
            ),
          ),
        );
      },
    );

    test(
      '400 con lista de errores se convierte en ValidationException',
      () async {
        adapter.reply = const FakeReply(400, {
          'errors': ['nombre requerido', 'correo inválido'],
        });

        expect(
          dataSource.getProfile(),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              'nombre requerido; correo inválido',
            ),
          ),
        );
      },
    );

    test('401 se convierte en UnauthorizedException', () async {
      adapter.reply = const FakeReply(401, {'message': 'token vencido'});

      expect(dataSource.getProfile(), throwsA(isA<UnauthorizedException>()));
    });

    test('timeout de conexión se convierte en NetworkException', () async {
      adapter.reply = const FakeReply.error(DioExceptionType.connectionTimeout);

      expect(dataSource.getProfile(), throwsA(isA<NetworkException>()));
    });

    test('500 con campo error usa ese texto', () async {
      adapter.reply = const FakeReply(500, {'error': 'Internal Server Error'});

      expect(
        dataSource.getProfile(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Internal Server Error',
          ),
        ),
      );
    });

    test('500 sin cuerpo útil usa el mensaje genérico', () async {
      adapter.reply = const FakeReply(500, {});

      expect(
        dataSource.getProfile(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Ocurrió un error inesperado en el servidor.',
          ),
        ),
      );
    });
  });

  group('OrganizerRemoteDataSource', () {
    late OrganizerRemoteDataSource dataSource;

    setUp(() => dataSource = OrganizerRemoteDataSource(dio: dioWith(adapter)));

    test('syncProfile envía POST /organizers/sync con el documento', () async {
      adapter.reply = const FakeReply(200, {'data': _organizer});

      final organizer = await dataSource.syncProfile(
        const SyncOrganizerParams(
          username: 'org.cauca',
          firstName: 'Org',
          lastName: 'Cauca',
          email: 'org@test.com',
          identificationDocument: '1061000000',
        ),
      );

      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/api/v1/organizers/sync');
      expect(
        adapter.last.data,
        containsPair('identificationDocument', '1061000000'),
      );
      expect(organizer.id, 9);
    });

    test('getProfile hace GET /organizers/me', () async {
      adapter.reply = const FakeReply(200, {'data': _organizer});

      final organizer = await dataSource.getProfile();

      expect(adapter.last.path, '/api/v1/organizers/me');
      expect(organizer.identificationDocument, '1061000000');
    });

    test('respuesta sin data lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {'data': 'no-es-un-mapa'});

      expect(dataSource.getProfile(), throwsA(isA<ServerException>()));
    });

    test('organizador sin id lanza ServerException de formato', () async {
      adapter.reply = const FakeReply(200, {
        'data': {'username': 'sin.id'},
      });

      expect(dataSource.getProfile(), throwsA(isA<ServerException>()));
    });

    test('409 se convierte en ConflictException', () async {
      adapter.reply = const FakeReply(409, {'message': 'Documento duplicado'});

      expect(dataSource.getProfile(), throwsA(isA<ConflictException>()));
    });

    test('400 se convierte en ValidationException', () async {
      adapter.reply = const FakeReply(400, {'message': 'Documento inválido'});

      expect(dataSource.getProfile(), throwsA(isA<ValidationException>()));
    });

    test('401 se convierte en UnauthorizedException', () async {
      adapter.reply = const FakeReply(401);

      expect(dataSource.getProfile(), throwsA(isA<UnauthorizedException>()));
    });

    test('sin conexión se convierte en NetworkException', () async {
      adapter.reply = const FakeReply.error(DioExceptionType.connectionError);

      expect(dataSource.getProfile(), throwsA(isA<NetworkException>()));
    });

    test('500 con cuerpo de texto usa ese texto', () async {
      adapter.reply = const FakeReply(500, 'Servicio caído');

      expect(
        dataSource.getProfile(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Servicio caído',
          ),
        ),
      );
    });

    test('500 con lista de errores la concatena', () async {
      adapter.reply = const FakeReply(500, {
        'errors': ['a', 'b'],
      });

      expect(
        dataSource.getProfile(),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'a; b'),
        ),
      );
    });
  });
}
