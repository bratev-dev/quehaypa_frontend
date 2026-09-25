import '../../domain/entities/interest.dart';

/// Modelo externo: conoce JSON. Convierte JSON -> Model -> Entity.
class InterestModel {
  final int id;
  final String name;

  const InterestModel({required this.id, required this.name});

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! num) {
      throw const FormatException('Campo id ausente o inválido en InterestModel');
    }
    return InterestModel(
      id: rawId.toInt(),
      name: json['name'] as String? ?? '',
    );
  }

  Interest toEntity() => Interest(id: id, name: name);
}
