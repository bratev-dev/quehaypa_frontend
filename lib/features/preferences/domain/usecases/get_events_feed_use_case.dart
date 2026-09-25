import '../entities/event_seed.dart';
import '../repositories/preferences_repository.dart';

class GetEventsFeed {
  final PreferencesRepository repository;

  const GetEventsFeed(this.repository);

  Future<List<EventSeed>> call() => repository.getFeed();
}
