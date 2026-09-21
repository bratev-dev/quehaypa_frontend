import '../repositories/preferences_repository.dart';

class SaveMyPreferences {
  final PreferencesRepository repository;

  const SaveMyPreferences(this.repository);

  Future<List<String>> call(List<String> categories) =>
      repository.saveMyPreferences(categories);
}
