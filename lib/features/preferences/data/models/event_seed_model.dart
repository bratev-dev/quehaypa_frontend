import '../../domain/entities/event_seed.dart';

/// Modelo externo para event_seed. JSON -> Model -> Entity.
class EventSeedModel {
  final int id;
  final String title;
  final String category;
  final String eventText;
  final String description;

  const EventSeedModel({
    required this.id,
    required this.title,
    required this.category,
    required this.eventText,
    this.description = '',
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
      eventText: json['eventText'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  EventSeed toEntity() => EventSeed(
    id: id,
    title: title,
    category: category,
    eventText: eventText,
    description: description,
  );
}
