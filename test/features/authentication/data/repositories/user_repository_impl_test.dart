import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/data/datasources/user_remote_data_source.dart';
import 'package:frontend/features/authentication/data/models/user_model.dart';
import 'package:frontend/features/authentication/data/repositories/user_repository_impl.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRemoteDataSource extends Mock
    implements UserRemoteDataSource {}

void main() {
  late MockUserRemoteDataSource remote;
  late UserRepositoryImpl repository;

  const params = SyncProfileParams(
    username: 'user.test',
    firstName: 'User',
    lastName: 'Test',
    email: 'user@test.com',
  );

  UserModel model() => const UserModel(
    id: 1,
    username: 'user.test',
    firstName: 'User',
    lastName: 'Test',
    email: 'user@test.com',
    isActive: true,
  );

  setUpAll(() {
    registerFallbackValue(params);
  });

  setUp(() {
    remote = MockUserRemoteDataSource();
    repository = UserRepositoryImpl(remoteDataSource: remote);
  });

  test('syncProfile retorna la entidad al éxito', () async {
    when(() => remote.syncProfile(any())).thenAnswer((_) async => model());

    final user = await repository.syncProfile(params);

    expect(user.username, 'user.test');
    verify(() => remote.syncProfile(any())).called(1);
  });

  test('409 se mapea a ConflictFailure', () {
    when(
      () => remote.syncProfile(any()),
    ).thenThrow(const ConflictException('El correo ya está en uso'));

    expect(
      repository.syncProfile(params),
      throwsA(
        isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          'El correo ya está en uso',
        ),
      ),
    );
  });

  test('400 se mapea a ValidationFailure', () {
    when(
      () => remote.syncProfile(any()),
    ).thenThrow(const ValidationException('Dato inválido'));

    expect(
      repository.syncProfile(params),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('401 se mapea a UnauthorizedFailure', () {
    when(
      () => remote.syncProfile(any()),
    ).thenThrow(const UnauthorizedException('No autorizado.'));

    expect(
      repository.syncProfile(params),
      throwsA(isA<UnauthorizedFailure>()),
    );
  });

  test('error de red se mapea a NetworkFailure', () {
    when(
      () => remote.syncProfile(any()),
    ).thenThrow(const NetworkException('Sin conexión'));

    expect(repository.syncProfile(params), throwsA(isA<NetworkFailure>()));
  });
}
