import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/data/datasources/organizer_remote_data_source.dart';
import 'package:frontend/features/authentication/data/models/organizer_model.dart';
import 'package:frontend/features/authentication/data/repositories/organizer_repository_impl.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockOrganizerRemoteDataSource extends Mock
    implements OrganizerRemoteDataSource {}

void main() {
  late MockOrganizerRemoteDataSource remote;
  late OrganizerRepositoryImpl repository;

  const params = SyncOrganizerParams(
    username: 'org.test',
    firstName: 'Org',
    lastName: 'Test',
    email: 'org@test.com',
    identificationDocument: 'CC-123',
  );

  OrganizerModel model() => const OrganizerModel(
    id: 7,
    username: 'org.test',
    firstName: 'Org',
    lastName: 'Test',
    email: 'org@test.com',
    identificationDocument: 'CC-123',
    isActive: true,
  );

  setUpAll(() {
    registerFallbackValue(params);
  });

  setUp(() {
    remote = MockOrganizerRemoteDataSource();
    repository = OrganizerRepositoryImpl(remoteDataSource: remote);
  });

  test('syncProfile retorna la entidad al éxito', () async {
    when(() => remote.syncProfile(any())).thenAnswer((_) async => model());

    final organizer = await repository.syncProfile(params);

    expect(organizer.identificationDocument, 'CC-123');
    verify(() => remote.syncProfile(any())).called(1);
  });

  test('409 se mapea a ConflictFailure', () {
    when(() => remote.syncProfile(any()))
        .thenThrow(const ConflictException('El documento ya está en uso'));

    expect(repository.syncProfile(params), throwsA(isA<ConflictFailure>()));
  });

  test('401 se mapea a UnauthorizedFailure', () {
    when(() => remote.syncProfile(any()))
        .thenThrow(const UnauthorizedException('No autorizado.'));

    expect(repository.syncProfile(params), throwsA(isA<UnauthorizedFailure>()));
  });

  test('error de red se mapea a NetworkFailure', () {
    when(() => remote.syncProfile(any()))
        .thenThrow(const NetworkException('Sin conexión'));

    expect(repository.syncProfile(params), throwsA(isA<NetworkFailure>()));
  });
}
