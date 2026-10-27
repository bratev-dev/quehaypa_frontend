import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/events/presentation/event_detail_page.dart';

import '../../helpers/fake_http_adapter.dart';

class _RegularSession extends AuthenticationController {
  @override
  AuthenticationState build() =>
      const AuthenticationState(status: AuthenticationStatus.authenticated);
}

void main() {
  testWidgets(
    'el detalle permanece visible si falla la inscripción y permite recuperarla',
    (tester) async {
      final adapter = FakeHttpAdapter();
      const event = FakeReply(200, {
        'data': {
          'id': 91,
          'title': 'Concierto persistido',
          'description': 'Descripción',
          'category': 'Música',
          'startsAt': '2099-01-01T18:00:00',
        },
      });
      adapter.queue.addAll([
        event,
        const FakeReply(503, {'message': 'Inscripción no disponible'}),
        event,
        const FakeReply(200, {
          'data': {'registered': false},
        }),
        const FakeReply(200, {
          'data': {'registered': true},
        }),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authenticationControllerProvider.overrideWith(_RegularSession.new),
            eventApiProvider.overrideWithValue(EventApi(dioWith(adapter))),
          ],
          child: const MaterialApp(home: EventDetailPage(eventId: 91)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Concierto persistido'), findsOneWidget);
      expect(find.text('Inscripción no disponible'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Reintentar inscripción'));
      await tester.pumpAndSettle();
      expect(find.text('Inscripción no disponible'), findsNothing);
      await tester.ensureVisible(find.text('Inscribirme'));
      await tester.tap(find.text('Inscribirme'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar inscripción'), findsOneWidget);
      expect(adapter.last.path, '/api/v1/events/91/registration/me');
      expect(adapter.last.method, 'POST');
    },
  );
}
