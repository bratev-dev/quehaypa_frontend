import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/events/presentation/event_image.dart';
import 'package:frontend/features/map/presentation/molecules/map_event_card.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/app/config/app_config.dart';
import 'package:frontend/app/config/app_config_provider.dart';
import 'package:frontend/app/config/environment.dart';

void main() {
  testWidgets('presenta los datos y cierra la tarjeta al tocar la X', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MapEventCard(
              event: const EventSeed(
                id: 1,
                title: 'Concierto en Popayán',
                category: 'Música',
                eventText: 'Hoy a las 7 p. m.',
                venue: 'Teatro Municipal',
                audience: 'ADULTS_ONLY',
                isPaid: true,
              ),
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Concierto en Popayán'), findsOneWidget);
    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Hoy a las 7 p. m.'), findsOneWidget);
    expect(find.text('Teatro Municipal'), findsOneWidget);
    expect(find.text('De pago'), findsOneWidget);
    expect(find.text('Mayores de edad'), findsOneWidget);
    expect(find.byType(EventImage), findsNothing);

    await tester.tap(find.bySemanticsLabel('Cerrar tarjeta del evento'));
    expect(closed, isTrue);
  });

  testWidgets('reserva espacio para la foto cuando el evento la tiene', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWith(
            (ref) => const AppConfig(
              environment: Environment.development,
              apiBaseUrl: 'https://example.invalid/',
              keycloakIssuer: '',
              keycloakClientId: '',
              keycloakRedirectUrl: '',
              keycloakEndSessionUrl: '',
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapEventCard(
              event: const EventSeed(
                id: 2,
                title: 'Exposición',
                category: 'Arte',
                eventText: 'Mañana',
                imageUrl: '/events/cover.jpg',
              ),
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(EventImage), findsOneWidget);
    expect(find.text('Gratuito'), findsOneWidget);
    expect(find.text('Mayores de edad'), findsNothing);
  });
}
