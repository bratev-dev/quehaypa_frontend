import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/domain/entities/event_coordinates.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/events/presentation/controllers/event_providers.dart';
import 'package:frontend/features/event_creation/presentation/controllers/event_creation_controller.dart';
import 'package:frontend/features/event_creation/presentation/pages/event_creation_page.dart';

import '../../../helpers/fake_http_adapter.dart';

void main() {
  EventCreationController ready() {
    final date = DateTime.now().add(const Duration(days: 1));
    final controller = EventCreationController()
      ..updateName('Concierto')
      ..updateCategory('Música')
      ..updateCity('Bogotá')
      ..updateAddress('Calle 1')
      ..selectCoordinates(const EventCoordinates(2.4448, -76.6147))
      ..updateDay('${date.day}')
      ..updateMonth('${date.month}')
      ..updateYear('${date.year}')
      ..updateStartTime(const TimeOfDay(hour: 18, minute: 0))
      ..updateEndTime(const TimeOfDay(hour: 20, minute: 0));
    controller.next();
    controller.next();
    return controller;
  }

  Future<void> mount(
    WidgetTester tester,
    EventCreationController controller,
    FakeHttpAdapter adapter,
  ) async {
    tester.view.physicalSize = const Size(402, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      controller.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventApiProvider.overrideWithValue(EventApi(dioWith(adapter))),
        ],
        child: MaterialApp(
          home: EventCreationPage(initialController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('solo confirma publicación después del servidor', (tester) async {
    final adapter = FakeHttpAdapter();
    adapter.queue.addAll([
      const FakeReply(200, {
        'data': [
          {'name': 'Música'},
        ],
      }),
      const FakeReply(200, {
        'data': [
          {'id': 1, 'name': 'Negocio demo'},
        ],
      }),
      const FakeReply(200, {'data': null}),
      const FakeReply(200, {
        'data': {'id': 'draft-1'},
      }),
      const FakeReply(201, {
        'data': {'id': 91, 'title': 'Concierto'},
      }),
    ]);
    await mount(tester, ready(), adapter);
    await tester.tap(find.text('Publicar evento'));
    await tester.pumpAndSettle();
    expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
    expect(adapter.requests.last.method, 'POST');
    final saved = adapter.requests.singleWhere(
      (request) => request.method == 'PUT',
    );
    final fields = (saved.data as Map)['fields'] as Map;
    final event = fields['event'] as Map;
    expect(event['latitude'], 2.4448);
    expect(event['longitude'], -76.6147);
  });

  testWidgets(
    'sube archivos de uno en uno y retoma desde el archivo que falló',
    (tester) async {
      final adapter = FakeHttpAdapter();
      adapter.queue.addAll([
        const FakeReply(200, {
          'data': [
            {'name': 'Música'},
          ],
        }),
        const FakeReply(200, {
          'data': [
            {'id': 1, 'name': 'Negocio demo'},
          ],
        }),
        const FakeReply(200, {'data': null}),
        const FakeReply(200, {
          'data': {'id': 'draft-1'},
        }),
        const FakeReply(200, {
          'data': {'id': 'file-1'},
        }),
        const FakeReply(503, {
          'message': 'No se pudo guardar el segundo archivo',
        }),
        const FakeReply(200, {
          'data': {'id': 'draft-1'},
        }),
        const FakeReply(200, {
          'data': {'id': 'file-2'},
        }),
        const FakeReply(200, {
          'data': {'id': 91, 'title': 'Concierto'},
        }),
      ]);
      final controller = ready();
      controller.addAttachment(
        EventAttachment(
          name: 'cover.png',
          sizeBytes: 1,
          bytes: Uint8List.fromList([1]),
        ),
      );
      controller.addAttachment(
        EventAttachment(
          name: 'entrada.pdf',
          sizeBytes: 1,
          bytes: Uint8List.fromList([2]),
        ),
      );
      await mount(tester, controller, adapter);
      await tester.tap(find.text('Publicar evento'));
      await tester.pumpAndSettle();
      expect(controller.attachments.first.id, 'file-1');
      expect(controller.attachments.last.id, isNull);
      expect(find.text('¡Evento creado con éxito!'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar evento'));
      await tester.pumpAndSettle();
      expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
      final uploads = adapter.requests
          .where((r) => r.path.endsWith('/attachments'))
          .toList();
      expect(uploads, hasLength(3));
      expect(
        uploads.map((r) => (r.data as FormData).files.single.value.filename),
        ['cover.png', 'entrada.pdf', 'entrada.pdf'],
      );
      expect(
        adapter.requests.where((r) => r.path.endsWith('/publish')),
        hasLength(1),
      );
    },
  );
  testWidgets('un fallo mantiene el formulario y permite reintentar', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter();
    adapter.queue.addAll([
      const FakeReply(200, {
        'data': [
          {'name': 'Música'},
        ],
      }),
      const FakeReply(200, {
        'data': [
          {'id': 1, 'name': 'Negocio demo'},
        ],
      }),
      const FakeReply(200, {'data': null}),
      const FakeReply(200, {
        'data': {'id': 'draft-1'},
      }),
      const FakeReply(503, {'message': 'Servidor no disponible'}),
    ]);
    await mount(tester, ready(), adapter);
    await tester.tap(find.text('Publicar evento'));
    await tester.pumpAndSettle();
    expect(find.text('¡Evento creado con éxito!'), findsNothing);
    expect(find.text('Servidor no disponible'), findsOneWidget);
    expect(find.text('Publicar evento'), findsOneWidget);
  });

  testWidgets(
    'restaura borrador y conserva los controles de GitHub sin ciudad',
    (tester) async {
      final adapter = FakeHttpAdapter();
      adapter.queue.addAll([
        const FakeReply(200, {
          'data': [
            {'name': 'Música'},
          ],
        }),
        const FakeReply(200, {
          'data': [
            {'id': 1, 'name': 'Negocio demo'},
          ],
        }),
        const FakeReply(200, {
          'data': {
            'id': 'draft-1',
            'fields': {
              'event': {
                'title': 'Mi borrador',
                'category': 'Música',
                'businessId': 1,
                'latitude': 2.4448,
                'longitude': -76.6147,
                'isPaid': true,
              },
              'step': 0,
            },
            'attachments': [],
          },
        }),
      ]);
      final controller = EventCreationController();
      await mount(tester, controller, adapter);
      expect(find.text('Mi borrador'), findsOneWidget);
      expect(find.text('Negocio demo'), findsOneWidget);
      expect(find.text('Ciudad'), findsNothing);
      expect(controller.isPaid, isTrue);
      expect(controller.coordinates?.latitude, 2.4448);
      expect(controller.coordinates?.longitude, -76.6147);
      expect(find.byTooltip('Cambiar ubicación del evento'), findsOneWidget);
      controller.step = EventCreationStep.details;
      controller.updateDescription('Detalles');
      await tester.pumpAndSettle();
      expect(find.text('El evento es de pago'), findsOneWidget);
      expect(find.text('JPG, PNG, PDF o MP4 · Máx. 50 MB'), findsOneWidget);
      controller.next();
      await tester.pumpAndSettle();
      expect(find.text('Guardar Borrador'), findsOneWidget);
      expect(find.text('Añadir enlaces de tu evento'), findsOneWidget);
    },
  );

  testWidgets(
    'reintenta una publicación sin duplicarla tras perder la respuesta',
    (tester) async {
      final adapter = FakeHttpAdapter();
      adapter.queue.addAll([
        const FakeReply(200, {
          'data': [
            {'name': 'Música'},
          ],
        }),
        const FakeReply(200, {
          'data': [
            {'id': 1, 'name': 'Negocio demo'},
          ],
        }),
        const FakeReply(200, {'data': null}),
        const FakeReply(200, {
          'data': {'id': 'draft-1'},
        }),
        const FakeReply.error(DioExceptionType.receiveTimeout),
        const FakeReply(200, {
          'data': {'id': 91, 'title': 'Concierto'},
        }),
      ]);
      await mount(tester, ready(), adapter);
      await tester.tap(find.text('Publicar evento'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar evento'));
      await tester.pumpAndSettle();
      expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
      final publications = adapter.requests
          .where((r) => r.path.endsWith('/publish'))
          .toList();
      expect(publications, hasLength(2));
      expect(publications[0].data, publications[1].data);
      expect(adapter.requests.where((r) => r.method == 'PUT'), hasLength(1));
    },
  );
}
