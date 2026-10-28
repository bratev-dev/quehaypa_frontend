import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/events/data/repositories/event_repository_impl.dart';
import 'package:frontend/features/events/domain/entities/event_draft.dart';
import 'package:frontend/features/events/domain/usecases/event_use_cases.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test(
    'crea el negocio acordado solo cuando no existe y reutiliza el ID remoto',
    () async {
      final adapter = FakeHttpAdapter()
        ..queue.addAll([
          const FakeReply(200, {'data': []}),
          const FakeReply(201, {
            'data': {'id': 19, 'name': 'Negocio demo'},
          }),
          const FakeReply(200, {
            'data': [
              {'id': 19, 'name': 'Negocio demo'},
            ],
          }),
        ]);
      final actions = EventRepositoryImpl(EventApi(dioWith(adapter)));
      expect((await actions.businesses()).single.id, '19');
      expect((await actions.businesses()).single.id, '19');
      expect(
        adapter.requests.where((request) => request.method == 'POST'),
        hasLength(1),
      );
      expect(adapter.requests[1].data, isNot(contains('ownerId')));
    },
  );

  test(
    'consulta el calendario y comparte datos y adjuntos del evento real',
    () async {
      const event = {
        'id': 7,
        'title': 'Jazz',
        'category': 'Música',
        'startsAt': '2026-12-01T18:00:00',
        'venue': 'Teatro',
        'isPaid': true,
        'description': 'En vivo',
        'links': ['https://example.com'],
        'attachments': [
          {
            'id': 'file-1',
            'name': 'foto.png',
            'contentType': 'image/png',
            'sizeBytes': 50,
            'url': '/api/v1/events/7/attachments/file-1',
          },
        ],
      };
      final adapter = FakeHttpAdapter()
        ..queue.addAll([
          const FakeReply(200, {
            'data': [event],
          }),
          const FakeReply(200, {'data': event}),
          const FakeReply(200, 'archivo'),
        ]);
      final actions = EventUseCases(
        EventRepositoryImpl(EventApi(dioWith(adapter))),
      );
      expect((await actions.organizerEvents()).single.id, 7);
      final text = await actions.shareEvent(7);
      expect(text, contains('Jazz'));
      expect(text, contains('Evento con entrada de pago'));
      expect(
        text,
        contains('https://api.test/api/v1/events/7/attachments/file-1'),
      );
      expect(await actions.draftAttachment('file-1'), isNotEmpty);
    },
  );
  test(
    'el borrador tipado conserva formulario incompleto y adjuntos',
    () async {
      final adapter = FakeHttpAdapter(
        const FakeReply(200, {
          'data': {
            'id': 'draft-1',
            'fields': {
              'day': '3',
              'month': '12',
              'year': '2026',
              'step': 1,
              'startHour': 18,
              'startMinute': 30,
              'endHour': 20,
              'endMinute': 0,
              'event': {
                'title': 'Jazz',
                'category': 'Música',
                'venue': 'Teatro',
                'description': 'En vivo',
                'businessId': 7,
                'isPaid': true,
                'audience': 'ADULTS_ONLY',
                'links': ['https://example.com'],
              },
            },
            'attachments': [
              {'id': 'file-1', 'name': 'foto.png', 'sizeBytes': 50},
            ],
          },
        }),
      );
      final repo = EventRepositoryImpl(EventApi(dioWith(adapter)));
      final draft = (await repo.draft())!;
      expect(draft.name, 'Jazz');
      expect(draft.day, '3');
      expect(draft.businessId, 7);
      expect(draft.adultsOnly, isTrue);
      expect(draft.attachments.single.id, 'file-1');
      adapter.reply = const FakeReply(200, {
        'data': {'id': 'draft-1'},
      });
      expect(await repo.saveDraft(draft), 'draft-1');
      final body = adapter.last.data as Map;
      expect(body['attachmentIds'], ['file-1']);
      expect(body['fields']['event']['businessId'], 7);
      expect(body['fields']['event']['isPaid'], isTrue);
      expect(body['fields']['day'], '3');
    },
  );

  for (final entry in <int, Type>{
    400: ValidationFailure,
    401: UnauthorizedFailure,
    403: UnauthorizedFailure,
    409: ConflictFailure,
    413: ValidationFailure,
    404: ServerFailure,
    500: ServerFailure,
  }.entries) {
    test(
      'HTTP ${entry.key} se transforma en Failure sin exponer Dio a la UI',
      () async {
        final repo = EventRepositoryImpl(
          EventApi(
            dioWith(
              FakeHttpAdapter(
                FakeReply(entry.key, {'message': 'Mensaje del backend'}),
              ),
            ),
          ),
        );
        await expectLater(
          repo.categories(),
          throwsA(
            predicate(
              (error) =>
                  error is Failure &&
                  error.runtimeType == entry.value &&
                  error.message == 'Mensaje del backend',
            ),
          ),
        );
      },
    );
  }
  test(
    'timeout y formato inválido se transforman en errores del dominio',
    () async {
      final adapter = FakeHttpAdapter(
        const FakeReply.error(DioExceptionType.connectionTimeout),
      );
      final repo = EventRepositoryImpl(EventApi(dioWith(adapter)));
      await expectLater(repo.categories(), throwsA(isA<NetworkFailure>()));
      adapter.reply = const FakeReply(200, {'data': null});
      await expectLater(repo.categories(), throwsA(isA<ServerFailure>()));
      expect(await repo.draft(), isNull);
      await expectLater(
        repo.uploadAttachment(
          'draft-1',
          const EventAttachment(name: 'foto.png', sizeBytes: 10),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );

  test(
    'el caso de uso carga categorías, negocios propios y borrador',
    () async {
      final adapter = FakeHttpAdapter()
        ..queue.addAll([
          const FakeReply(200, {
            'data': [
              {'name': 'Música'},
            ],
          }),
          const FakeReply(200, {
            'data': [
              {'id': 7, 'name': 'Mi negocio'},
            ],
          }),
          const FakeReply(200, {'data': null}),
        ]);
      final data = await EventUseCases(
        EventRepositoryImpl(EventApi(dioWith(adapter))),
      ).loadCreation();
      expect(data.categories, ['Música']);
      expect(data.businesses.single.id, '7');
      expect(data.draft, isNull);
      expect(adapter.requests.map((request) => request.path), [
        '/api/v1/business-categories',
        '/api/v1/businesses/me',
        '/api/v1/events/draft/me',
      ]);
    },
  );
}
