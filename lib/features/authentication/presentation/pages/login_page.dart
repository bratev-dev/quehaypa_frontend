import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      body: switch (authenticationState.status) {
        AuthenticationStatus.initial ||
        AuthenticationStatus.loading => const SafeArea(
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
        ),

        AuthenticationStatus.error => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    authenticationState.errorMessage ??
                        'Ocurrió un error al autenticar.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(authenticationControllerProvider.notifier)
                          .login();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038FF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Intentar nuevamente'),
                  ),
                ],
              ),
            ),
          ),
        ),

        _ => LoginTemplate(
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
      },
    );
  }
}
