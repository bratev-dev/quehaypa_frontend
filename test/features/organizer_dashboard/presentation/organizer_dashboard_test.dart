import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/events/presentation/controllers/event_providers.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/organizer_dashboard/presentation/organisms/organizer_calendar_map.dart';
import 'package:frontend/features/organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

void main() {
  testWidgets('la navegación del organizador abre el mapa real', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [organizerEventsProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: OrganizerDashboardPage(preview: true)),
      ),
    );

    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Falta configurar el token público de Mapbox para mostrar el mapa.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el calendario muestra eventos persistidos del servidor', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerEventsProvider.overrideWith(
            (ref) async => [
              EventSeed(
                id: 91,
                title: 'Concierto persistido',
                category: 'Música',
                eventText: '18:00',
                startsAt: DateTime(
                  today.year,
                  today.month,
                  today.day,
                  18,
                ).toIso8601String(),
                endsAt: DateTime(
                  today.year,
                  today.month,
                  today.day,
                  20,
                ).toIso8601String(),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OrganizerCalendarMap())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Concierto persistido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('un fallo del catálogo ofrece reintentar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizerEventsProvider.overrideWith(
            (ref) async => throw Exception('offline'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OrganizerCalendarMap())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
