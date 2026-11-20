import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/plans/data/datasources/plan_remote_data_source.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';

import '../../../../helpers/fake_http_adapter.dart';

const _plan = {
  'id': 3,
  'title': 'Noche de jazz',
  'description': 'Con los amigos',
  'meetingDate': '2026-10-02T20:00:00',
  'userRole': 'CREATOR',
};

void main() {
  late FakeHttpAdapter adapter;
  late PlanRemoteDataSource dataSource;

  setUp(() {
    adapter = FakeHttpAdapter();
    dataSource = PlanRemoteDataSource(dio: dioWith(adapter));
  });

  group('getMyPlans', () {
    test('hace GET /plans/my-plans y parsea la lista', () async {
      adapter.reply = const FakeReply(200, {
        'data': [_plan],
      });

      final plans = await dataSource.getMyPlans();

      expect(adapter.last.method, 'GET');
      expect(adapter.last.path, '/api/v1/plans/my-plans');
      expect(plans, hasLength(1));
      expect(plans.single.title, 'Noche de jazz');
      expect(plans.single.meetingDate, DateTime(2026, 10, 2, 20));
    });

    test('data que no es lista lanza ServerException', () async {
      adapter.reply = const FakeReply(200, {'data': _plan});

      expect(dataSource.getMyPlans(), throwsA(isA<ServerException>()));
    });

    test('un plan sin id lanza ServerException de formato', () async {
      adapter.reply = const FakeReply(200, {
        'data': [
          {'title': 'sin id'},
        ],
      });

      expect(
        dataSource.getMyPlans(),
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

  group('createPlan', () {
    test('hace POST /plans con la fecha en formato del backend (sin zona ni milisegundos)', () async {
      adapter.reply = const FakeReply(201, {'data': _plan});

      final plan = await dataSource.createPlan(
        CreatePlanParams(
          title: 'Noche de jazz',
          description: 'Con los amigos',
          meetingDate: DateTime(2026, 10, 2, 20, 5, 9),
        ),
      );

      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/api/v1/plans');
      expect(
        adapter.last.data,
        containsPair('meetingDate', '2026-10-02T20:05:09'),
      );
      expect(plan.id, 3);
    });

    test('sin fecha no envía meetingDate', () async {
      adapter.reply = const FakeReply(201, {'data': _plan});

      await dataSource.createPlan(
        const CreatePlanParams(title: 'Sin fecha', description: ''),
      );

      expect((adapter.last.data as Map).containsKey('meetingDate'), isFalse);
    });

    test('respuesta sin data lanza ServerException', () async {
      adapter.reply = const FakeReply(201, {'message': 'creado'});

      expect(
        dataSource.createPlan(
          const CreatePlanParams(title: 'x', description: ''),
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('400 se convierte en ValidationException con el mensaje', () async {
      adapter.reply = const FakeReply(400, {
        'message': 'El título es obligatorio',
      });

      expect(
        dataSource.createPlan(
          const CreatePlanParams(title: '', description: ''),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'El título es obligatorio',
          ),
        ),
      );
    });
  });

  group('updatePlan', () {
    test('hace PUT /plans/{id}/edit', () async {
      adapter.reply = const FakeReply(200, {'data': _plan});

      await dataSource.updatePlan(
        UpdatePlanParams(
          planId: 3,
          title: 'Nuevo',
          description: 'd',
          meetingDate: DateTime(2026, 1, 2, 3, 4, 5),
        ),
      );

      expect(adapter.last.method, 'PUT');
      expect(adapter.last.path, '/api/v1/plans/3/edit');
      expect(
        adapter.last.data,
        containsPair('meetingDate', '2026-01-02T03:04:05'),
      );
    });

    test(
      '403 (plan ajeno) se convierte en UnauthorizedException de permisos',
      () async {
        adapter.reply = const FakeReply(403, {'message': 'Solo el creador'});

        expect(
          dataSource.updatePlan(
            const UpdatePlanParams(planId: 3, title: 'x', description: 'y'),
          ),
          throwsA(
            isA<UnauthorizedException>()
                .having((e) => e.statusCode, 'statusCode', 403)
                .having(
                  (e) => e.message,
                  'message',
                  'No tienes permisos para esta operación.',
                ),
          ),
        );
      },
    );

    test('envía meetingDate nulo para quitar una fecha existente', () async {
      adapter.reply = const FakeReply(200, {'data': _plan});

      await dataSource.updatePlan(
        const UpdatePlanParams(planId: 3, title: 'Sin fecha'),
      );

      expect(adapter.last.data, containsPair('meetingDate', null));
    });
  });

  group('deletePlan', () {
    test('hace DELETE /plans/{id}/delete', () async {
      adapter.reply = const FakeReply(200, {'message': 'eliminado'});

      await dataSource.deletePlan(3);

      expect(adapter.last.method, 'DELETE');
      expect(adapter.last.path, '/api/v1/plans/3/delete');
    });

    test('404 se convierte en ServerException con el mensaje', () async {
      adapter.reply = const FakeReply(404, {'message': 'Plan no encontrado'});

      expect(
        dataSource.deletePlan(99),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Plan no encontrado',
          ),
        ),
      );
    });

    test('401 se convierte en UnauthorizedException', () async {
      adapter.reply = const FakeReply(401);

      expect(dataSource.deletePlan(3), throwsA(isA<UnauthorizedException>()));
    });

    test('409 se convierte en ConflictException', () async {
      adapter.reply = const FakeReply(409, {'error': 'conflicto'});

      expect(dataSource.deletePlan(3), throwsA(isA<ConflictException>()));
    });

    test('timeout de envío se convierte en NetworkException', () async {
      adapter.reply = const FakeReply.error(DioExceptionType.sendTimeout);

      expect(dataSource.deletePlan(3), throwsA(isA<NetworkException>()));
    });

    test(
      '500 con texto plano usa ese texto; sin cuerpo, el genérico',
      () async {
        adapter.reply = const FakeReply(500, 'caído');
        await expectLater(
          dataSource.deletePlan(3),
          throwsA(
            isA<ServerException>().having((e) => e.message, 'message', 'caído'),
          ),
        );

        adapter.reply = const FakeReply(500, {});
        await expectLater(
          dataSource.deletePlan(3),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'Ocurrió un error inesperado en el servidor.',
            ),
          ),
        );
      },
    );
  });

  group('plan events', () {
    const event = {
      'id': 7,
      'title': 'Concierto',
      'category': 'Música',
      'eventText': 'Viernes 20:00',
      'description': 'En vivo',
    };

    test('addEvent envía el id y parsea el evento guardado', () async {
      adapter.reply = const FakeReply(201, {'data': event});

      final saved = await dataSource.addEvent(3, 7);

      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/api/v1/plans/3/items');
      expect(adapter.last.data, {'eventId': 7});
      expect(saved.id, 7);
      expect(saved.title, 'Concierto');
    });

    test('getPlanEvents devuelve la lista del plan', () async {
      adapter.reply = const FakeReply(200, {
        'data': [event],
      });

      final events = await dataSource.getPlanEvents(3);

      expect(adapter.last.method, 'GET');
      expect(adapter.last.path, '/api/v1/plans/3/items');
      expect(events.single.id, 7);
    });

    test('addEvent convierte una respuesta inválida en ServerException', () {
      adapter.reply = const FakeReply(201, {'data': []});

      expect(dataSource.addEvent(3, 7), throwsA(isA<ServerException>()));
    });

    test('getPlanEvents rechaza una lista con evento inválido', () {
      adapter.reply = const FakeReply(200, {
        'data': [
          {'title': 'Sin id'},
        ],
      });

      expect(dataSource.getPlanEvents(3), throwsA(isA<ServerException>()));
    });

    test('addEvent convierte duplicados en ConflictException', () {
      adapter.reply = const FakeReply(409, {
        'message': 'Este evento ya está guardado en el plan',
      });

      expect(dataSource.addEvent(3, 7), throwsA(isA<ConflictException>()));
    });

    test('removeEvent borra solo la asociación del evento indicado', () async {
      adapter.reply = const FakeReply(200, {
        'message': 'Evento quitado del plan',
      });

      await dataSource.removeEvent(3, 7);

      expect(adapter.last.method, 'DELETE');
      expect(adapter.last.path, '/api/v1/plans/3/items/7');
    });

    test('removeEvent no considera éxito un evento ausente', () {
      adapter.reply = const FakeReply(404, {
        'message': 'El evento no está guardado en este plan',
      });

      expect(dataSource.removeEvent(3, 7), throwsA(isA<ServerException>()));
    });
  });
}
