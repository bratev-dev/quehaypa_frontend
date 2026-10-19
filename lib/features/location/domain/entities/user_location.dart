/// De dónde salió la ubicación que usa la app.
enum LocationSource {
  /// Posición actual del dispositivo.
  device,

  /// Última posición que el sistema tenía guardada (el GPS no respondió).
  lastKnown,

  /// Popayán: no hay permiso o no hubo ninguna posición disponible.
  defaultCity,
}

/// Ubicación con la que la app busca contenido cercano. Solo vive en memoria:
/// no se envía al backend ni se guarda.
class UserLocation {
  final double latitude;
  final double longitude;
  final LocationSource source;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  /// Popayán, Parque Caldas: respaldo de HU-5.1 (CA2 y CA3).
  static const defaultCity = UserLocation(
    latitude: 2.4419,
    longitude: -76.6063,
    source: LocationSource.defaultCity,
  );

  bool get isDefaultCity => source == LocationSource.defaultCity;
}
