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
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationControllerProvider);

    // Escuchamos los cambios de estado para manejar errores con nuestro AppSnackbar unificado
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.status == AuthenticationStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(context, next.errorMessage!);
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
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              onTogglePassword: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              onLoginPressed: () {
                ref.read(authenticationControllerProvider.notifier).login();
              },
              onRegisterPressed: () {
                context.go(RoutePaths.register);
              },
            ),
    );
  }
}
