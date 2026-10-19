/// Evento creado en esta sesión hasta que la publicación use el backend.
class CreatedEventPreview {
  const CreatedEventPreview({
    required this.title,
    required this.startsAt,
    required this.endsAt,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
}
