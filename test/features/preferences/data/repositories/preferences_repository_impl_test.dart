import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';
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
}
