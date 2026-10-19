/// Estado del permiso de ubicación en el sistema operativo, sin depender del
/// paquete que lo consulta.
enum LocationPermissionStatus {
  /// Concedido (precisa o aproximada).
  granted,

  /// Rechazado, pero el sistema todavía permite volver a pedirlo.
  denied,

  /// Rechazado de forma permanente: solo se cambia desde los ajustes del sistema.
  deniedForever,
}
