import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/app/router/route_paths.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';

void main() {
  test('registro pendiente permite rol y bloquea acceso al dashboard', () {
    const pending = AuthenticationStatus.registrationRequired;
    expect(authenticationRedirect(pending, RoutePaths.register), isNull);
    for (final route in [
      RoutePaths.home,
      RoutePaths.dashboard,
      RoutePaths.myPlans,
    ]) {
      expect(authenticationRedirect(pending, route), RoutePaths.register);
    }
  });

  test('login o registro completado redirige al dashboard', () {
    for (final route in [
      RoutePaths.home,
      RoutePaths.login,
      RoutePaths.register,
    ]) {
      expect(
        authenticationRedirect(AuthenticationStatus.authenticated, route),
        RoutePaths.dashboard,
      );
    }
  });

  test(
    'cancelar conserva el vídeo y no permite registro ni rutas privadas',
    () {
      const cancelled = AuthenticationStatus.unauthenticated;
      expect(authenticationRedirect(cancelled, RoutePaths.home), isNull);
      for (final route in [
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.dashboard,
        RoutePaths.myPlans,
      ]) {
        expect(authenticationRedirect(cancelled, route), RoutePaths.home);
      }
    },
  );

  test('espera mientras restaura la sesión o Keycloak está abierto', () {
    for (final status in [
      AuthenticationStatus.initial,
      AuthenticationStatus.loading,
    ]) {
      expect(authenticationRedirect(status, RoutePaths.home), isNull);
    }
  });
}
