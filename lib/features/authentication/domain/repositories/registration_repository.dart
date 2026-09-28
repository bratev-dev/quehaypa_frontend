abstract class RegistrationRepository {
  /// true = registro pendiente; false = cuenta completa.
  Future<bool> begin();
  Future<void> complete();
  Future<void> cancel();
}
