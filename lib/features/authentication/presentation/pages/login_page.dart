import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../atoms/app_snackbar.dart';
import '../controllers/authentication_controller.dart';
import '../controllers/authentication_state.dart';
import '../templates/login_template.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationControllerProvider);

    // Escuchamos los cambios de estado para manejar errores con nuestro AppSnackbar unificado
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.status == AuthenticationStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(
          context,
          message: next.errorMessage!,
          type: SnackbarType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      body: authenticationState.status == AuthenticationStatus.loading
          ? const SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0038FF)),
                    SizedBox(height: 16),
                    Text(
                      'Abriendo sesión con Keycloak...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          : LoginTemplate(
              emailController: _emailController,
              onLoginPressed: () {
                final email = _emailController.text.trim();

                if (email.isNotEmpty) {
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(email)) {
                    AppSnackbar.show(
                      context,
                      message:
                          'El formato del correo electrónico no es válido.',
                      type: SnackbarType.info, // Alerta naranja institucional
                    );
                    return;
                  }
                }

                // Disparamos el login hacia Keycloak
                ref.read(authenticationControllerProvider.notifier).login();
              },
              onRegisterPressed: () {
                context.go(RoutePaths.register);
              },
            ),
    );
  }
}
