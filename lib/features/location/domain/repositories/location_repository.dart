import '../entities/location_consent.dart';
import '../entities/location_permission_status.dart';
import '../entities/user_location.dart';

/// Contrato de la ubicación: qué se puede hacer, no cómo.
abstract class LocationRepository {
  /// Respuesta guardada de la cuenta, o null si nunca se le preguntó.
  Future<LocationConsent?> getConsent(String accountId);

  Future<void> saveConsent(String accountId, LocationConsent consent);

  Future<LocationPermissionStatus> checkPermission();

  /// Muestra el diálogo del sistema (si el sistema aún lo permite).
  Future<LocationPermissionStatus> requestPermission();

  /// Posición actual, o null si el GPS está apagado o no responde a tiempo.
  Future<UserLocation?> getCurrentLocation({required Duration timeLimit});

  /// Última posición guardada por el sistema, o null si no hay ninguna.
  Future<UserLocation?> getLastKnownLocation();

  /// Abre los ajustes de la app en el sistema. Devuelve false si no pudo.
  Future<bool> openAppSettings();
}
