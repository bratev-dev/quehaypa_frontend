import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';

import '../../../../helpers/fake_http_adapter.dart';

const _event = {
  'id': 1,
  'title': 'Noche de Jazz',
  'category': 'Música',
  'eventText': 'Hoy',
  'description': 'Concierto',
};

void main() {
  late FakeHttpAdapter adapter;
  late PreferencesRemoteDataSource dataSource;

  setUp(() {
    adapter = FakeHttpAdapter();
    dataSource = PreferencesRemoteDataSource(dio: dioWith(adapter));
  });

  group('preferencias propias', () {
    test(
      'saveMyPreferences hace PUT /preferences/me con las categorías',
      () async {
        adapter.reply = const FakeReply(200, {
          'data': ['Música', 'Cine'],
        });

        final saved = await dataSource.saveMyPreferences(['Musica', 'Cine']);

        expect(adapter.last.method, 'PUT');
        expect(adapter.last.path, '/api/v1/preferences/me');
        expect(adapter.last.data, {
          'categories': ['Musica', 'Cine'],
        });
        expect(saved, ['Música', 'Cine']);
      },
    );

    test(
      'saveMyPreferences con data que no es lista lanza ServerException',
      () async {
        adapter.reply = const FakeReply(200, {'data': 'x'});

        expect(
          dataSource.saveMyPreferences(['Cine']),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test('getMyPreferences hace GET /preferences/me', () async {
      adapter.reply = const FakeReply(200, {
        'data': ['Arte'],
      });

      expect(await dataSource.getMyPreferences(), ['Arte']);
      expect(adapter.last.method, 'GET');
    });

    test('getMyPreferences sin lista lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {});

      expect(dataSource.getMyPreferences(), throwsA(isA<ServerException>()));
    });
  });

  group('catálogo de intereses', () {
    test('getInterests hace GET /interests y parsea el catálogo', () async {
      adapter.reply = const FakeReply(200, {
        'data': [
          {'id': 1, 'name': 'Música'},
          {'id': 2, 'name': 'Cine'},
        ],
      });

      final interests = await dataSource.getInterests();

      expect(adapter.last.path, '/api/v1/interests');
      expect(interests.map((i) => i.name), ['Música', 'Cine']);
    });

    test('catálogo que no es lista lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {'data': {}});

      expect(dataSource.getInterests(), throwsA(isA<ServerException>()));
    });

    test('interés sin id lanza ServerException de formato', () async {
      adapter.reply = const FakeReply(200, {
        'data': [
          {'name': 'sin id'},
        ],
      });

      expect(
        dataSource.getInterests(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('formato inesperado'),
          ),
        ),
      );
    });
  });

  group('eventos', () {
    test('getFeed hace GET /events/feed/me', () async {
      adapter.reply = const FakeReply(200, {
        'data': [_event],
      });

      final feed = await dataSource.getFeed();

      expect(adapter.last.path, '/api/v1/events/feed/me');
      expect(feed.single.category, 'Música');
    });

    test('getEvents con categoría la envía como query', () async {
      adapter.reply = const FakeReply(200, {
        'data': [_event],
      });

      await dataSource.getEvents(category: 'Música');

      expect(adapter.last.path, '/api/v1/events');
      expect(adapter.last.queryParameters, {
        'category': 'Música',
        'page': 0,
        'size': 50,
      });
    });

    test('getEvents sin categoría envía paginación', () async {
      adapter.reply = const FakeReply(200, {'data': []});

      expect(await dataSource.getEvents(), isEmpty);
      expect(adapter.last.queryParameters, {'page': 0, 'size': 50});
    });

    test('lista de eventos inválida lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {'data': null});

      expect(dataSource.getFeed(), throwsA(isA<ServerException>()));
    });

    test('evento sin id lanza ServerException de formato', () async {
      adapter.reply = const FakeReply(200, {
        'data': [
          {'title': 'sin id'},
        ],
      });

      expect(dataSource.getEvents(), throwsA(isA<ServerException>()));
    });
  });

  group('mapeo de errores HTTP', () {
    test('400 se convierte en ValidationException con el mensaje', () async {
      adapter.reply = const FakeReply(400, {
        'message': 'Categoría inválida: X',
      });

      expect(
        dataSource.saveMyPreferences(['X']),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Categoría inválida: X',
          ),
        ),
      );
    });

    test('401 se convierte en UnauthorizedException', () async {
      adapter.reply = const FakeReply(401);

      expect(dataSource.getFeed(), throwsA(isA<UnauthorizedException>()));
    });

    test('403 se convierte en UnauthorizedException de permisos', () async {
      adapter.reply = const FakeReply(403);

      expect(
        dataSource.getMyPreferences(),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'No tienes permisos para esta operación.',
          ),
        ),
      );
    });

    test('404 se convierte en ServerException con el mensaje', () async {
      adapter.reply = const FakeReply(404, {'message': 'Perfil no encontrado'});

      expect(
        dataSource.getMyPreferences(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Perfil no encontrado',
          ),
        ),
      );
    });

    test('timeout de respuesta se convierte en NetworkException', () async {
      adapter.reply = const FakeReply.error(DioExceptionType.receiveTimeout);

      expect(dataSource.getInterests(), throwsA(isA<NetworkException>()));
    });

    test('500 con texto plano usa ese texto', () async {
      adapter.reply = const FakeReply(500, 'caído');

      expect(
        dataSource.getEvents(),
        throwsA(
          isA<ServerException>().having((e) => e.message, 'message', 'caído'),
        ),
      );
    });

    test('500 sin cuerpo útil usa el mensaje genérico', () async {
      adapter.reply = const FakeReply(500, {});

      expect(
        dataSource.getEvents(),
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
}
