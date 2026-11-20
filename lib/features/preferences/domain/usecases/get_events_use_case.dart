import '../entities/event_seed.dart';
import '../repositories/preferences_repository.dart';

class GetEvents {
  final PreferencesRepository repository;
  const GetEvents(this.repository);

  Future<List<EventSeed>> call({String? category}) =>
      repository.getEvents(category: category);

  Future<List<EventSeed>> nearby({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) => repository.getNearbyEvents(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
}
