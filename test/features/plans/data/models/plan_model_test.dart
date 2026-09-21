import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/plans/data/models/plan_model.dart';

void main() {
  test('PlanModel.fromJson parsea envelope del back', () {
    final model = PlanModel.fromJson({
      'id': 7,
      'title': 'Plan de prueba',
      'description': 'Descripción',
      'meetingDate': '2026-10-15T20:00:00',
      'userRole': 'CREATOR',
    });

    expect(model.id, 7);
    expect(model.title, 'Plan de prueba');
    expect(model.userRole, 'CREATOR');
    expect(model.meetingDate?.year, 2026);

    final entity = model.toEntity();
    expect(entity.id, 7);
    expect(entity.isCreator, isTrue);
  });

  test('PlanModel lanza FormatException sin id', () {
    expect(
      () => PlanModel.fromJson({'title': 'Sin id'}),
      throwsA(isA<FormatException>()),
    );
  });
}
