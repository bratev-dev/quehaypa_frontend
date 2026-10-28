/// Entidad de negocio: evento quemado (seed) vinculado a un interés.
/// Fase temporal QHP-78 hasta que exista el módulo de eventos.
class EventSeed {
  final int id;
  final String title;
  final String category;
  final String eventText;
  final String description;
  final String? imageUrl;
  final String? city;
  final String? venue;
  final String? startsAt;
  final String? endsAt;
  final String? audience;
  final int? businessId;
  final bool isPaid;
  final List<String> links;
  final List<EventFile> attachments;

  const EventSeed({
    required this.id,
    required this.title,
    required this.category,
    required this.eventText,
    this.description = '',
    this.imageUrl,
    this.city,
    this.venue,
    this.startsAt,
    this.endsAt,
    this.audience,
    this.businessId,
    this.isPaid = false,
    this.links = const [],
    this.attachments = const [],
  });
}

class EventFile {
  const EventFile({
    required this.id,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.url,
  });
  final String id, name, contentType, url;
  final int sizeBytes;
}
