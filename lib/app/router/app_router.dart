import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/authentication_controller.dart';
import '../../features/authentication/presentation/controllers/authentication_state.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_plans/presentation/pages/my_plans_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';
import 'route_paths.dart';
import 'router_refresh_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefreshNotifier = RouterRefreshNotifier();

  ref.listen<AuthenticationState>(authenticationControllerProvider, (
    previous,
    next,
  ) {
    if (previous?.status != next.status ||
        previous?.isOrganizer != next.isOrganizer) {
      routerRefreshNotifier.refresh();
    }
  });

  ref.onDispose(routerRefreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: routerRefreshNotifier,

    redirect: (context, state) {
      return authenticationRedirect(
        ref.read(authenticationControllerProvider).status,
        state.matchedLocation,
        isOrganizer: ref.read(authenticationControllerProvider).isOrganizer,
      );
    },

    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: RouteNames.login,
        path: RoutePaths.login,
        redirect: (context, state) => RoutePaths.home,
      ),
      GoRoute(
        name: RouteNames.register,
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        name: RouteNames.home,
        path: RoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: RouteNames.dashboard,
        path: RoutePaths.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        name: RouteNames.myPlans,
        path: RoutePaths.myPlans,
        builder: (context, state) => const MyPlansPage(),
      ),
    ],
  );
});

/// Decide el destino sin construir pantallas ni abrir el navegador.
String? authenticationRedirect(
  AuthenticationStatus authenticationStatus,
  String matchedLocation, {
  bool isOrganizer = false,
}) {
  if (authenticationStatus == AuthenticationStatus.authenticated &&
      isOrganizer &&
      matchedLocation == RoutePaths.myPlans) {
    return RoutePaths.dashboard;
  }
  final status = authenticationStatus;
  final isAuthenticated = status == AuthenticationStatus.authenticated;

  if (status == AuthenticationStatus.initial ||
      status == AuthenticationStatus.loading) {
    return null;
  }

  if (status == AuthenticationStatus.registrationRequired) {
    return matchedLocation == RoutePaths.register ? null : RoutePaths.register;
  }

  // Las rutas antiguas ya no muestran formularios de credenciales.
  if (!isAuthenticated &&
      (matchedLocation == RoutePaths.login ||
          matchedLocation == RoutePaths.register)) {
    return RoutePaths.home;
  }

  final isPublicRoute =
      matchedLocation == RoutePaths.login ||
      matchedLocation == RoutePaths.register ||
      matchedLocation == RoutePaths.splash ||
      matchedLocation == RoutePaths.home;

  // Si ya está autenticado y se encuentra en pantallas públicas, mándalo al Dashboard
  if (isAuthenticated && isPublicRoute) {
    return RoutePaths.dashboard;
  }

  // Tras cerrar sesión, la navegación privada vuelve al menú del video.
  if (!isAuthenticated && matchedLocation == RoutePaths.dashboard) {
    return RoutePaths.home;
  }

  if (!isAuthenticated && matchedLocation == RoutePaths.myPlans) {
    return RoutePaths.home;
  }

  return null;
}
