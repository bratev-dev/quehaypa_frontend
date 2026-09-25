/// Entidad de negocio Plan. No conoce Dio, JSON ni Flutter.
class Plan {
  final int id;
  final String title;
  final String description;
  final DateTime? meetingDate;
  final String userRole;

  const Plan({
    required this.id,
    required this.title,
    this.description = '',
    this.meetingDate,
    this.userRole = '',
  });

  bool get isCreator => userRole == 'CREATOR';
}
