import '../entities/event_seed.dart';
import '../entities/interest.dart';

/// Contrato del dominio para intereses del usuario regular.
abstract class PreferencesRepository {
  /// Guarda y retorna las categorias persistidas en el back.
  Future<List<String>> saveMyPreferences(List<String> categories);

  /// Lee las preferencias guardadas (GET /api/v1/preferences/me).
  Future<List<String>> getMyPreferences();

  /// Catalogo real del back (GET /api/v1/interests, publico).
  Future<List<Interest>> getInterests();

  /// Feed de eventos quemados filtrado por mis intereses.
  Future<List<EventSeed>> getFeed();

  /// Lista completa de eventos quemados, con filtro opcional por categoria.
  Future<List<EventSeed>> getEvents({String? category});
}
