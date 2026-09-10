import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Función auxiliar para mostrar alertas flotantes
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F), // Rojo elegante
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationControllerProvider);
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      body: switch (authenticationState.status) {
        AuthenticationStatus.initial || 
        AuthenticationStatus.loading => 
          const SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0038FF)),
                  SizedBox(height: 16),
                  Text('Cargando elementos...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

        AuthenticationStatus.error => 
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      authenticationState.errorMessage ?? 'Ocurrió un error inesperado.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(authenticationControllerProvider.notifier).login();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0038FF), foregroundColor: Colors.white),
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
              final email = _emailController.text.trim();
              final password = _passwordController.text;

              // Validaciones manuales con mensajes limpios
              if (email.isEmpty) {
                _showErrorSnackBar('Por favor ingresa tu correo electrónico.');
                return;
              }
              if (!emailRegex.hasMatch(email)) {
                _showErrorSnackBar('El formato del correo electrónico no es válido.');
                return;
              }
              if (password.isEmpty) {
                _showErrorSnackBar('Por favor ingresa tu contraseña.');
                return;
              }

              // Si todo es correcto, ejecuta el login
              ref.read(authenticationControllerProvider.notifier).login();
            },
          ),
      },
    );
  }
}