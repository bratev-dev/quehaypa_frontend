import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/events/presentation/controllers/event_providers.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/organizer_dashboard/presentation/organisms/organizer_calendar_map.dart';

void main() {
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
