import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../templates/register_template.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return Scaffold(
      backgroundColor: const Color(
        0xFF0A47ED,
      ), // Mantiene la línea conceptual de fondo
      body: RegisterTemplate(
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        onTogglePassword: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        termsAccepted: _termsAccepted,
        onTermsChanged: (value) {
          setState(() {
            _termsAccepted = value ?? false;
          });
        },
        onRegisterPressed: () {
          final email = _emailController.text.trim();
          final password = _passwordController.text;

          if (email.isEmpty) {
            _showErrorSnackBar('Por favor ingresa tu correo electrónico.');
            return;
          }
          if (!emailRegex.hasMatch(email)) {
            _showErrorSnackBar(
              'El formato del correo electrónico no es válido.',
            );
            return;
          }
          if (password.isEmpty) {
            _showErrorSnackBar('Por favor ingresa tu contraseña.');
            return;
          }
          if (password.length < 6) {
            _showErrorSnackBar(
              'La contraseña debe tener al menos 6 caracteres.',
            );
            return;
          }
          if (!_termsAccepted) {
            _showErrorSnackBar('Debes aceptar los términos y condiciones.');
            return;
          }

          // TODO: Conectar con el RegisterController de Riverpod próximamente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso (Simulado)!')),
          );
        },
        onLoginRedirectPressed: () {
          context.go(RoutePaths.login);
        },
      ),
    );
  }
}
