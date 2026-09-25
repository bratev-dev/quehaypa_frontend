import '../repositories/preferences_repository.dart';
import '../entities/interest.dart';

class GetInterests {
  final PreferencesRepository repository;

  const GetInterests(this.repository);

  Future<List<Interest>> call() => repository.getInterests();
}
