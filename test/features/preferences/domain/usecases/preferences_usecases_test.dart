import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/domain/usecases/get_events_feed_use_case.dart';
import 'package:frontend/features/preferences/domain/usecases/get_interests_use_case.dart';
import 'package:frontend/features/preferences/domain/usecases/get_my_preferences_use_case.dart';
import 'package:frontend/features/preferences/domain/usecases/save_preferences_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

void main() {
  late MockPreferencesRepository repository;

  setUp(() {
    repository = MockPreferencesRepository();
  });

  test('GetInterests delega al repositorio', () async {
    when(() => repository.getInterests()).thenAnswer(
      (_) async => const [Interest(id: 1, name: 'Musica')],
    );

    final result = await GetInterests(repository)();

    expect(result, hasLength(1));
    expect(result.first.name, 'Musica');
    verify(() => repository.getInterests()).called(1);
  });

  test('GetMyPreferences delega al repositorio', () async {
    when(() => repository.getMyPreferences())
        .thenAnswer((_) async => ['Musica', 'Cine']);

    final result = await GetMyPreferences(repository)();

    expect(result, ['Musica', 'Cine']);
    verify(() => repository.getMyPreferences()).called(1);
  });

  test('SaveMyPreferences delega al repositorio', () async {
    when(() => repository.saveMyPreferences(any()))
        .thenAnswer((_) async => ['Musica']);

    final result =
        await SaveMyPreferences(repository)(['Musica']);

    expect(result, ['Musica']);
    verify(() => repository.saveMyPreferences(['Musica'])).called(1);
  });

  test('GetEventsFeed delega al repositorio', () async {
    when(() => repository.getFeed()).thenAnswer(
      (_) async => const [
        EventSeed(
          id: 1,
          title: 'Noche de Jazz',
          category: 'Musica',
          eventText: '15 Oct',
        ),
      ],
    );

    final result = await GetEventsFeed(repository)();

    expect(result, hasLength(1));
    expect(result.first.category, 'Musica');
    verify(() => repository.getFeed()).called(1);
  });
}
