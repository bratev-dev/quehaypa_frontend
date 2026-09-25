/// Entidad de negocio: evento quemado (seed) vinculado a un interés.
/// Fase temporal QHP-78 hasta que exista el módulo de eventos.
class EventSeed {
  final int id;
  final String title;
  final String category;
  final String eventText;
  final String description;

  const EventSeed({
    required this.id,
    required this.title,
    required this.category,
    required this.eventText,
    this.description = '',
  });
}
