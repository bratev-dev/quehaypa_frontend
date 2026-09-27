import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers/network_providers.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_state.dart';
import 'package:frontend/features/dashboard/presentation/molecules/event_card.dart';
import 'package:frontend/features/dashboard/presentation/organisms/dashboard_feed_view.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_http_adapter.dart';

class _Repository extends Mock implements PreferencesRepository {}

const _event = EventSeed(
  id: 9,
  title: 'Desde el servidor',
  category: 'Cine',
  eventText: 'Información de la API',
);

void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    when(() => repository.getMyPreferences()).thenAnswer((_) async => ['Cine']);
    when(() => repository.getFeed()).thenAnswer((_) async => [_event]);
    container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpFeed(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DashboardFeedView())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('muestra carga y luego tarjetas con los datos recibidos', (
    tester,
  ) async {
    final pending = Completer<List<EventSeed>>();
    when(() => repository.getFeed()).thenAnswer((_) => pending.future);
    await pumpFeed(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(EventCard), findsNothing);
    pending.complete([_event]);
    await tester.pumpAndSettle();
    final card = tester.widget<EventCard>(find.byType(EventCard));
    expect(card.title, 'Desde el servidor');
    expect(card.category, 'Cine');
    expect(card.date, 'Información de la API');
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('lista vacía muestra el estado vacío sin eventos locales', (
    tester,
  ) async {
    when(() => repository.getFeed()).thenAnswer((_) async => []);
    await pumpFeed(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('No hay eventos para tus intereses por ahora.'),
      findsOneWidget,
    );
    expect(find.byType(EventCard), findsNothing);
  });

  testWidgets('un fallo muestra reintento y recupera la lista', (tester) async {
    when(() => repository.getFeed())
        .thenThrow(const NetworkFailure('Sin conexión'));
    await pumpFeed(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.byType(EventCard), findsNothing);
    when(() => repository.getFeed()).thenAnswer((_) async => [_event]);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(EventCard), findsOneWidget);
    expect(find.text('Sin conexión'), findsNothing);
  });

  testWidgets('frontend completo consulta HTTP y filtra por categoría', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(const FakeReply(200, {'data': []}));
    // El feed se solicita antes de recuperar las preferencias.
    adapter.queue.addAll([
      const FakeReply(200, {
        'data': [
          {
            'id': 17,
            'title': 'API HTTP',
            'category': 'Cine',
            'eventText': 'Hoy',
            'description': '',
          },
        ],
      }),
      const FakeReply(200, {
        'data': ['Cine'],
      }),
    ]);
    final connected = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dioWith(adapter))],
    );
    addTearDown(connected.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: connected,
        child: const MaterialApp(home: Scaffold(body: DashboardFeedView())),
      ),
    );
    await tester.pumpAndSettle();
    expect(adapter.requests.map((r) => r.path), [
      '/api/v1/events/feed/me',
      '/api/v1/preferences/me',
    ]);
    expect(tester.widget<EventCard>(find.byType(EventCard)).title, 'API HTTP');
    connected.read(dashboardControllerProvider.notifier).selectCategory('Cine');
    await tester.pumpAndSettle();
    expect(adapter.last.path, '/api/v1/events');
    expect(adapter.last.queryParameters, {'category': 'Cine'});
    expect(
      connected.read(dashboardControllerProvider).status,
      DashboardStatus.success,
    );
    expect(find.byType(EventCard), findsNothing);
  });
}
