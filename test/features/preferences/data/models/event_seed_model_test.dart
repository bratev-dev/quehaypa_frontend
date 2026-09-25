import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/data/models/event_seed_model.dart';

void main() {
  test('EventSeedModel.fromJson parsea evento quemado', () {
    final model = EventSeedModel.fromJson({
      'id': 1,
      'title': 'Noche de Jazz en el Centro',
      'category': 'Musica',
      'eventText': '15 Oct - 8:00 PM',
      'description': 'Jazz en vivo',
    });

    expect(model.id, 1);
    expect(model.category, 'Musica');

    final entity = model.toEntity();
    expect(entity.title, 'Noche de Jazz en el Centro');
    expect(entity.eventText, '15 Oct - 8:00 PM');
  });

  test('EventSeedModel lanza FormatException sin id', () {
    expect(
      () => EventSeedModel.fromJson({'title': 'Sin id'}),
      throwsA(isA<FormatException>()),
    );
  });
}
