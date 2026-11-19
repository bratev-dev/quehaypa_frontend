import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/map/presentation/map_event_card_details.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';

void main() {
  test('presenta fecha, horas, lugar y etiquetas de un evento de pago', () {
    const event = EventSeed(
      id: 1,
      title: 'Concierto',
      category: 'Música',
      eventText: '',
      startsAt: '2026-11-18T19:30:00',
      endsAt: '2026-11-18T22:00:00',
      venue: 'Teatro Municipal',
      city: 'Popayán',
      isPaid: true,
      audience: 'ADULTS_ONLY',
    );

    final details = MapEventCardDetails.fromEvent(event);
    expect(details.when, 'Mié 18 nov · 7:30 p. m. – 10:00 p. m.');
    expect(details.where, 'Teatro Municipal');
    expect(details.price, 'De pago');
    expect(details.adultsOnly, isTrue);
  });

  test('usa ciudad y texto de fecha cuando faltan datos estructurados', () {
    const event = EventSeed(
      id: 2,
      title: 'Exposición',
      category: 'Arte',
      eventText: 'Próximamente',
      city: 'Popayán',
    );

    final details = MapEventCardDetails.fromEvent(event);
    expect(details.when, 'Próximamente');
    expect(details.where, 'Popayán');
    expect(details.price, 'Gratuito');
    expect(details.adultsOnly, isFalse);
  });

  test('muestra datos por confirmar cuando tampoco hay texto de respaldo', () {
    const event = EventSeed(
      id: 3,
      title: 'Taller',
      category: 'Arte',
      eventText: ' ',
    );

    final details = MapEventCardDetails.fromEvent(event);
    expect(details.when, 'Fecha por confirmar');
    expect(details.where, 'Lugar por confirmar');
  });

  test('no une las horas de fechas distintas', () {
    const event = EventSeed(
      id: 4,
      title: 'Festival',
      category: 'Música',
      eventText: '',
      startsAt: '2026-11-18T23:00:00',
      endsAt: '2026-11-19T02:00:00',
    );

    expect(
      MapEventCardDetails.fromEvent(event).when,
      'Mié 18 nov · 11:00 p. m.',
    );
  });
}
