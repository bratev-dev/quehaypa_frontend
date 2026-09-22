/// Parámetros de dominio para crear / actualizar un plan.
/// Sin JSON ni Dio: solo datos de negocio.
class CreatePlanParams {
  final String title;
  final String description;
  final DateTime? meetingDate;

  const CreatePlanParams({
    required this.title,
    this.description = '',
    this.meetingDate,
  });
}

class UpdatePlanParams {
  final int planId;
  final String title;
  final String description;
  final DateTime? meetingDate;

  const UpdatePlanParams({
    required this.planId,
    required this.title,
    this.description = '',
    this.meetingDate,
  });
}
