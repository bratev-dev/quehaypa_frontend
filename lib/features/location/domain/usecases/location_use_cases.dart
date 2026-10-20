import '../entities/location_consent.dart';
import '../entities/location_permission_status.dart';
import '../entities/user_location.dart';
import '../repositories/location_repository.dart';

/// Resultado de buscar la ubicación: la que se usará y si el dispositivo falló
/// teniendo permiso (para avisar "No pudimos obtener tu ubicación", CA3).
class LocationResolution {
  final UserLocation location;
  final bool deviceUnavailable;

  const LocationResolution(this.location, {this.deviceUnavailable = false});
}

class GetLocationConsent {
  final LocationRepository repository;

  const GetLocationConsent(this.repository);

  Future<LocationConsent?> call(String accountId) =>
      repository.getConsent(accountId);
}

/// "Ahora no": se recuerda para esa cuenta y no se le vuelve a preguntar.
class DeclineLocationAccess {
  final LocationRepository repository;

  const DeclineLocationAccess(this.repository);

  Future<void> call(String accountId) =>
      repository.saveConsent(accountId, LocationConsent.declined);
}

/// "Permitir" (o reactivar desde Configuración): recuerda la respuesta y pide el
/// permiso del sistema solo si todavía se puede pedir. Si el sistema lo bloqueó
/// y [openSettingsIfBlocked] es true, abre los ajustes de la app (CA5).
class RequestLocationAccess {
  final LocationRepository repository;

  const RequestLocationAccess(this.repository);

  Future<LocationPermissionStatus> call(
    String accountId, {
    bool openSettingsIfBlocked = false,
  }) async {
    await repository.saveConsent(accountId, LocationConsent.granted);
    var status = await repository.checkPermission();
    if (status == LocationPermissionStatus.denied) {
      status = await repository.requestPermission();
    }
    if (status == LocationPermissionStatus.deniedForever &&
        openSettingsIfBlocked) {
      await repository.openAppSettings();
    }
    return status;
  }
}

/// Regla de HU-5.1. Si la cuenta no aceptó o el sistema no da permiso:
/// Popayán. Si no, la posición actual (máximo [timeLimit]); si el GPS no
/// responde, la última conocida; si tampoco hay, Popayán. Nunca vuelve a pedir
/// el permiso por su cuenta. Se consulta la cuenta porque el permiso del
/// sistema es del teléfono: otra cuenta pudo haberlo concedido.
class ResolveUserLocation {
  static const timeLimit = Duration(seconds: 10);

  final LocationRepository repository;

  const ResolveUserLocation(this.repository);

  Future<LocationResolution> call(String accountId) async {
    final consent = await repository.getConsent(accountId);
    if (consent != LocationConsent.granted) {
      return const LocationResolution(UserLocation.defaultCity);
    }

    final status = await repository.checkPermission();
    if (status != LocationPermissionStatus.granted) {
      return const LocationResolution(UserLocation.defaultCity);
    }

    final current = await repository.getCurrentLocation(timeLimit: timeLimit);
    if (current != null) {
      return LocationResolution(current);
    }

    final lastKnown = await repository.getLastKnownLocation();
    return LocationResolution(
      lastKnown ?? UserLocation.defaultCity,
      deviceUnavailable: true,
    );
  }
}
