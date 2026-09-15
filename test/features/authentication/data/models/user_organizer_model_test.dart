import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/data/models/organizer_model.dart';
import 'package:frontend/features/authentication/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson mapea todos los campos y toEntity conserva datos', () {
      final model = UserModel.fromJson({
        'id': 3,
        'username': 'user.test',
        'firstName': 'User',
        'lastName': 'Test',
        'email': 'user@test.com',
        'birthDate': '2000-05-20',
        'profilePictureUrl': 'http://img/pic.png',
        'isActive': true,
      });

      expect(model.id, 3);
      expect(model.birthDate, DateTime(2000, 5, 20));

      final entity = model.toEntity();
      expect(entity.username, 'user.test');
      expect(entity.firstName, 'User');
      expect(entity.email, 'user@test.com');
      expect(entity.isActive, isTrue);
    });

    test('birthDate inválida queda en null sin romper el parseo', () {
      final model = UserModel.fromJson({
        'id': 1,
        'username': 'u',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.com',
        'birthDate': 'no-es-fecha',
      });

      expect(model.birthDate, isNull);
    });

    test('id ausente lanza FormatException', () {
      expect(
        () => UserModel.fromJson({'username': 'u'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OrganizerModel', () {
    test('fromJson mapea documento, razón y teléfono', () {
      final model = OrganizerModel.fromJson({
        'id': 7,
        'username': 'org.test',
        'firstName': 'Org',
        'lastName': 'Test',
        'email': 'org@test.com',
        'identificationDocument': 'CC-7',
        'reason': 'Registro app',
        'contactPhone': '0000000000',
        'isActive': true,
      });

      final entity = model.toEntity();
      expect(entity.identificationDocument, 'CC-7');
      expect(entity.reason, 'Registro app');
      expect(entity.contactPhone, '0000000000');
    });

    test('id ausente lanza FormatException', () {
      expect(
        () => OrganizerModel.fromJson({'username': 'org'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
