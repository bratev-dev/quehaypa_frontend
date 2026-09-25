import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';
import 'package:frontend/features/preferences/data/models/event_seed_model.dart';
import 'package:frontend/features/preferences/data/models/interest_model.dart';
import 'package:frontend/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesRemoteDataSource extends Mock
    implements PreferencesRemoteDataSource {}

void main() {
  late MockPreferencesRemoteDataSource remote;
  late PreferencesRepositoryImpl repository;

  setUp(() {
    remote = MockPreferencesRemoteDataSource();
    repository = PreferencesRepositoryImpl(remoteDataSource: remote);
  });

  test('saveMyPreferences retorna categorías persistidas', () async {
    when(() => remote.saveMyPreferences(any()))
        .thenAnswer((_) async => ['Música', 'Cine']);

    final result = await repository.saveMyPreferences(['Música', 'Cine']);

    expect(result, ['Música', 'Cine']);
    verify(() => remote.saveMyPreferences(['Música', 'Cine'])).called(1);
  });

  test('400 se mapea a ValidationFailure', () {
    when(() => remote.saveMyPreferences(any()))
        .thenThrow(const ValidationException('Mínimo 1 categoría'));

    expect(repository.saveMyPreferences([]), throwsA(isA<ValidationFailure>()));
  });

  test('getMyPreferences retorna guardadas', () async {
    when(() => remote.getMyPreferences()).thenAnswer((_) async => ['Musica']);

    final result = await repository.getMyPreferences();

    expect(result, ['Musica']);
    verify(() => remote.getMyPreferences()).called(1);
  });

  test('getInterests mapea Model a Entity', () async {
    when(() => remote.getInterests())
        .thenAnswer((_) async => const [InterestModel(id: 1, name: 'Musica')]);

    final result = await repository.getInterests();

    expect(result, hasLength(1));
    expect(result.first.name, 'Musica');
  });

  test('getFeed mapea Model a Entity', () async {
    when(() => remote.getFeed()).thenAnswer(
      (_) async => const [
        EventSeedModel(
          id: 1,
          title: 'Noche de Jazz',
          category: 'Musica',
          eventText: '15 Oct',
        ),
      ],
    );

    final result = await repository.getFeed();

    expect(result, hasLength(1));
    expect(result.first.category, 'Musica');
  });

  test('401 en getInterests se mapea a UnauthorizedFailure', () {
    when(() => remote.getInterests())
        .thenThrow(const UnauthorizedException('No autorizado.'));

    expect(repository.getInterests(), throwsA(isA<UnauthorizedFailure>()));
  });
}
