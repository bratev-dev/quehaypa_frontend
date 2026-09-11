import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/authentication_controller.dart';
import '../../features/authentication/presentation/controllers/authentication_state.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
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
    if (previous?.status != next.status) {
      routerRefreshNotifier.refresh();
    }
  });

  ref.onDispose(routerRefreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: routerRefreshNotifier,

    redirect: (context, state) {
      final authenticationState = ref.read(authenticationControllerProvider);

      final status = authenticationState.status;
      final isAuthenticated = status == AuthenticationStatus.authenticated;

      final matchedLocation = state.matchedLocation;

      if (status == AuthenticationStatus.initial ||
          status == AuthenticationStatus.loading) {
        return null;
      }

      final isPublicRoute = matchedLocation == RoutePaths.login ||
          matchedLocation == RoutePaths.register ||
          matchedLocation == RoutePaths.splash ||
          matchedLocation == RoutePaths.home;

      // Si ya está autenticado y se encuentra en pantallas públicas, mándalo al Dashboard
      if (isAuthenticated && isPublicRoute) {
        return RoutePaths.dashboard;
      }

      // Si no está autenticado y trata de estar en el dashboard, mándalo al Home
      if (!isAuthenticated && matchedLocation == RoutePaths.dashboard) {
        return RoutePaths.home;
      }

      return null;
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
        builder: (context, state) => const LoginPage(),
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
    ],
  );
});