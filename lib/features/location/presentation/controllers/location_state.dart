import '../../domain/entities/user_location.dart';

enum LocationStatus { idle, checking, askingConsent, resolving, ready }

/// Aviso breve que el feed muestra una sola vez tras un cambio.
enum LocationNotice {
  usingDefaultCity(
    'Usaremos Popayán como referencia. Puedes activar tu ubicación en '
    'Configuración.',
  ),
  usingLastKnown(
    'No pudimos obtener tu ubicación actual. Usaremos la última conocida.',
  ),
  unavailable(
    'No pudimos obtener tu ubicación. Usaremos Popayán como referencia.',
  );

  final String message;

  const LocationNotice(this.message);
}

class LocationState {
  final LocationStatus status;
  final String? accountId;
  final UserLocation location;
  final LocationNotice? notice;

  const LocationState({
    this.status = LocationStatus.idle,
    this.accountId,
    this.location = UserLocation.defaultCity,
    this.notice,
  });

  /// Como errorMessage en los demás estados, [notice] se limpia si no se pasa.
  LocationState copyWith({
    LocationStatus? status,
    UserLocation? location,
    LocationNotice? notice,
  }) {
    return LocationState(
      status: status ?? this.status,
      accountId: accountId,
      location: location ?? this.location,
      notice: notice,
    );
  }
}
