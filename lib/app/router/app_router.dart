import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/authentication_controller.dart';
import '../../features/authentication/presentation/controllers/authentication_state.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'route_names.dart';
import 'route_paths.dart';
import 'router_refresh_notifier.dart';

CustomTransitionPage<void> _slideTransitionPage({
  required LocalKey key,
  required Widget child,
  required Offset beginOffset,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          );

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

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
    // La app inicia en el Home (que ahora tiene el video y los botones)
    initialLocation: RoutePaths.home,

    refreshListenable: routerRefreshNotifier,

    redirect: (context, state) {
      final authenticationState = ref.read(authenticationControllerProvider);

      final status = authenticationState.status;
      final isAuthenticated = status == AuthenticationStatus.authenticated;

      final matchedLocation = state.matchedLocation;
      final isGoingToLogin = matchedLocation == RoutePaths.login;
      // final isGoingToHome = matchedLocation == RoutePaths.home;

      if (status == AuthenticationStatus.initial ||
          status == AuthenticationStatus.loading) {
        return null;
      }

      // Si ya está autenticado y trata de ir al login o al home de bienvenida,
      // puedes redirigirlo a la pantalla principal interna de la app cuando la tengas.
      // Por ahora lo dejamos libre o ajustado a tus necesidades.
      if (isAuthenticated && isGoingToLogin) {
        // return RoutePaths.someAuthenticatedRoute;
      }

      return null;
    },

    routes: [
      // Ruta del Login, con transición desde la izquierda (al volver de Registro)
      GoRoute(
        name: RouteNames.login,
        path: RoutePaths.login,
        pageBuilder: (context, state) {
          return _slideTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            beginOffset: const Offset(-1.0, 0.0),
          );
        },
      ),
      // Ruta del Registro, con transición desde la derecha (al avanzar desde Login)
      GoRoute(
        name: RouteNames.register,
        path: RoutePaths.register,
        pageBuilder: (context, state) {
          return _slideTransitionPage(
            key: state.pageKey,
            child: const RegisterPage(),
            beginOffset: const Offset(1.0, 0.0),
          );
        },
      ),
      // Ruta del Home (Pantalla inicial con el video y botones)
      GoRoute(
        name: RouteNames.home,
        path: RoutePaths.home,
        builder: (context, state) {
          return const HomePage();
        },
      ),
    ],
  );
});
