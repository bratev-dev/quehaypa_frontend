/// Contrato del dominio para intereses del usuario regular.
abstract class PreferencesRepository {
  /// Guarda y retorna las categorías persistidas en el back.
  Future<List<String>> saveMyPreferences(List<String> categories);
}
