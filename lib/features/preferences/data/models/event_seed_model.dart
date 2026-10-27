import '../../domain/entities/event_seed.dart';

/// Modelo externo para event_seed. JSON -> Model -> Entity.
class EventSeedModel {
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

  const EventSeedModel({
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

  factory EventSeedModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! num) {
      throw const FormatException(
        'Campo id ausente o inválido en EventSeedModel',
      );
    }
    return EventSeedModel(
      id: rawId.toInt(),
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      eventText: (json['eventText'] ?? json['startsAt'] ?? '')
          .toString()
          .replaceFirst('T', ' '),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      city: json['city'] as String?,
      venue: json['venue'] as String?,
      startsAt: json['startsAt'] as String?,
      endsAt: json['endsAt'] as String?,
      audience: json['audience'] as String?,
      businessId: (json['businessId'] as num?)?.toInt(),
      isPaid: json['isPaid'] == true,
      links: (json['links'] as List? ?? []).cast<String>(),
      attachments: (json['attachments'] as List? ?? [])
          .map(
            (a) => EventFile(
              id: a['id'] as String,
              name: a['name'] as String,
              contentType: a['contentType'] as String,
              sizeBytes: (a['sizeBytes'] as num).toInt(),
              url: a['url'] as String,
            ),
          )
          .toList(),
    );
  }

  EventSeed toEntity() => EventSeed(
    id: id,
    title: title,
    category: category,
    eventText: eventText,
    description: description,
    imageUrl: imageUrl,
    city: city,
    venue: venue,
    startsAt: startsAt,
    endsAt: endsAt,
    audience: audience,
    businessId: businessId,
    isPaid: isPaid,
    links: links,
    attachments: attachments,
  );
}
