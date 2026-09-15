class AppErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString();

    // Si es un error de descubrimiento o red de Keycloak / AppAuth
    if (errorString.contains('discovery_failed') ||
        errorString.contains('Network error') ||
        errorString.contains('FileNotFoundException') ||
        errorString.contains('socketexception')) {
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
