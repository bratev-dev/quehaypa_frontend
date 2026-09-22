import '../../domain/entities/plan.dart';

/// Modelo externo: conoce JSON. Convierte JSON -> Model -> Entity.
class PlanModel {
  final int id;
  final String title;
  final String description;
  final DateTime? meetingDate;
  final String userRole;

  const PlanModel({
    required this.id,
    required this.title,
    this.description = '',
    this.meetingDate,
    this.userRole = '',
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! num) {
      throw const FormatException('Campo id ausente o inválido en PlanModel');
    }

    DateTime? meetingDate;
    final rawDate = json['meetingDate'];
    if (rawDate is String && rawDate.isNotEmpty) {
      meetingDate = DateTime.tryParse(rawDate);
    }

    return PlanModel(
      id: rawId.toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      meetingDate: meetingDate,
      userRole: json['userRole'] as String? ?? '',
    );
  }

  Plan toEntity() {
    return Plan(
      id: id,
      title: title,
      description: description,
      meetingDate: meetingDate,
      userRole: userRole,
    );
  }
}
