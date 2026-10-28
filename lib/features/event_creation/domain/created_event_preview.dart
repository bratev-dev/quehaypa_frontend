/// Evento confirmado por el backend para enfocar su fecha en el calendario.
class CreatedEventPreview {
  const CreatedEventPreview({
    required this.title,
    this.id,
    this.imageUrl,
    required this.startsAt,
    required this.endsAt,
  });

  final String title;
  final int? id;
  final String? imageUrl;
  final DateTime startsAt;
  final DateTime endsAt;
}
