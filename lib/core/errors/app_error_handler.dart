class AppErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    // Se normaliza a minúsculas una sola vez: `SocketException.toString()`
    // y otros errores de plataforma vienen con mayúsculas variables, y
    // `String.contains` en Dart es sensible a mayúsculas.
    final errorString = error.toString().toLowerCase();

    // Si es un error de descubrimiento o red de Keycloak / AppAuth
    // (incluye el servidor de Keycloak caído o inalcanzable).
    if (errorString.contains('discovery_failed') ||
        errorString.contains('network error') ||
        errorString.contains('filenotfoundexception') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out')) {
      return 'No pudimos conectar con el servidor de autenticación. Verifica tu conexión a internet o intenta más tarde.';
    }

    // Si es un error de credenciales incorrectas
    if (errorString.contains('invalid_grant') ||
        errorString.contains('unauthorized')) {
      return 'Correo o contraseña incorrectos. Por favor, verifica tus datos.';
    }

    // Mensaje por defecto genérico para cualquier otra cosa inesperada
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}
