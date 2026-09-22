/// Eventos QUEMADOS (mock temporal QHP-78).
/// TODO(QHP-78): reemplazar por GET /api/v1/events del monolito cuando
/// exista el módulo de eventos. Por ahora el dashboard filtra en memoria
/// por los intereses del usuario (filtrado local acordado).
class MockedEvent {
  final String title;
  final String category;
  final String date;

  const MockedEvent({
    required this.title,
    required this.category,
    required this.date,
  });
}

const List<MockedEvent> kMockedEvents = [
  MockedEvent(
    title: 'Noche de Jazz en el Centro',
    category: 'Música',
    date: '15 Oct - 8:00 PM',
  ),
  MockedEvent(
    title: 'Hackatón Regional de Tecnología',
    category: 'Tecnología',
    date: '18 Oct - 9:00 AM',
  ),
  MockedEvent(
    title: 'Torneo Relámpago de Fútbol 5',
    category: 'Deportes',
    date: '19 Oct - 4:00 PM',
  ),
  MockedEvent(
    title: 'Exposición de Arte Local',
    category: 'Arte',
    date: '20 Oct - 6:00 PM',
  ),
  MockedEvent(
    title: 'Cine al Parque: Clásicos',
    category: 'Cine',
    date: '21 Oct - 7:00 PM',
  ),
  MockedEvent(
    title: 'Feria Gastronómica Popayán',
    category: 'Gastronomía',
    date: '22 Oct - 12:00 PM',
  ),
  MockedEvent(
    title: 'Club de Lectura: Crónica Urbana',
    category: 'Lectura',
    date: '23 Oct - 5:00 PM',
  ),
  MockedEvent(
    title: 'Meetup de Fotografía Nocturna',
    category: 'Fotografía',
    date: '24 Oct - 7:30 PM',
  ),
];
