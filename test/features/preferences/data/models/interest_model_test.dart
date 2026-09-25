import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/data/models/interest_model.dart';

void main() {
  test('InterestModel.fromJson parsea catalogo del back', () {
    final model = InterestModel.fromJson({'id': 5, 'name': 'Cine'});

    expect(model.id, 5);
    expect(model.name, 'Cine');

    final entity = model.toEntity();
    expect(entity.id, 5);
    expect(entity.name, 'Cine');
  });

  test('InterestModel lanza FormatException sin id', () {
    expect(
      () => InterestModel.fromJson({'name': 'Sin id'}),
      throwsA(isA<FormatException>()),
    );
  });
}
