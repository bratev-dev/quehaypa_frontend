import '../repositories/preferences_repository.dart';

class GetMyPreferences {
  final PreferencesRepository repository;

  const GetMyPreferences(this.repository);

  Future<List<String>> call() => repository.getMyPreferences();
}
