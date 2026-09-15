import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/organizer.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/organizer_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockOrganizerRepository extends Mock
    implements OrganizerRepository {}

void main() {
  const profileParams = SyncProfileParams(
    username: 'user.test',
    firstName: 'User',
    lastName: 'Test',
    email: 'user@test.com',
  );

  const organizerParams = SyncOrganizerParams(
    username: 'org.test',
    firstName: 'Org',
    lastName: 'Test',
    email: 'org@test.com',
    identificationDocument: 'CC-123',
  );

  const user = User(
    id: 1,
    username: 'user.test',
    firstName: 'User',
    lastName: 'Test',
    email: 'user@test.com',
    isActive: true,
  );

  const organizer = Organizer(
    id: 7,
    username: 'org.test',
    firstName: 'Org',
    lastName: 'Test',
    email: 'org@test.com',
    identificationDocument: 'CC-123',
    isActive: true,
  );

  setUpAll(() {
    registerFallbackValue(profileParams);
    registerFallbackValue(organizerParams);
  });

  test('SyncProfileUseCase delega al repositorio con los mismos params',
      () async {
    final repository = MockUserRepository();
    when(
      () => repository.syncProfile(any()),
    ).thenAnswer((_) async => user);

    final result = await SyncProfileUseCase(repository)(profileParams);

    expect(result.username, 'user.test');
    verify(() => repository.syncProfile(profileParams)).called(1);
  });

  test('SyncOrganizerUseCase delega al repositorio con los mismos params',
      () async {
    final repository = MockOrganizerRepository();
    when(
      () => repository.syncProfile(any()),
    ).thenAnswer((_) async => organizer);

    final result = await SyncOrganizerUseCase(repository)(organizerParams);

    expect(result.identificationDocument, 'CC-123');
    verify(() => repository.syncProfile(organizerParams)).called(1);
  });
}
