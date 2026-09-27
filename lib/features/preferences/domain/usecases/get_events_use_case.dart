import '../entities/event_seed.dart';
import '../repositories/preferences_repository.dart';

class GetEvents {
  final PreferencesRepository repository;
  const GetEvents(this.repository);

  Future<List<EventSeed>> call({required String category}) =>
      repository.getEvents(category: category);
}
