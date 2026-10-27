import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test('publica JSON e imagen como multipart y conserva el ID real', () async {
    final adapter = FakeHttpAdapter(
      const FakeReply(201, {
        'data': {
          'id': 91,
          'title': 'Concierto',
          'startsAt': '2026-12-01T18:00:00',
          'imageUrl': '/api/v1/events/91/image',
        },
      }),
    );
    final api = EventApi(dioWith(adapter));
    final event = await api.publish(
      {'title': 'Concierto'},
      image: Uint8List.fromList([1, 2]),
      filename: 'cover.png',
    );
    expect(event.id, 91);
    expect(event.imageUrl, '/api/v1/events/91/image');
    final form = adapter.last.data as FormData;
    expect(form.files.map((e) => e.key), containsAll(['event', 'image']));
    expect(form.files.first.value.contentType?.mimeType, 'application/json');
  });

  test('lee catálogo paginado y no confunde inscripción con planes', () async {
    final adapter = FakeHttpAdapter(
      const FakeReply(200, {
        'data': {
          'content': [
            {'id': 91, 'title': 'Concierto', 'startsAt': '2026-12-01T18:00:00'},
          ],
          'totalPages': 1,
        },
      }),
    );
    final dio = dioWith(adapter);
    final events = await PreferencesRemoteDataSource(dio: dio).getEvents();
    expect(events.single.id, 91);
    final api = EventApi(dio);
    adapter.reply = const FakeReply(200, {
      'data': {'registered': true},
    });
    await api.setRegistered(91, true);
    expect(adapter.last.path, '/api/v1/events/91/registration/me');
    expect(adapter.last.method, 'POST');
    expect(await api.registration(91), isTrue);
    await api.setRegistered(91, false);
    expect(adapter.last.method, 'DELETE');
  });

  test('un error de publicación se propaga sin inventar un evento', () async {
    final adapter = FakeHttpAdapter(
      const FakeReply(400, {'message': 'Fecha inválida'}),
    );
    final api = EventApi(dioWith(adapter));
    await expectLater(
      api.publish(jsonDecode('{"title":"Prueba"}') as Map<String, dynamic>),
      throwsA(isA<DioException>()),
    );
  });
}
