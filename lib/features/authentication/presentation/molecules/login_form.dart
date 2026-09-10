import 'package:flutter/material.dart';
import '../atoms/primary_button.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLoginPressed;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo Correo Electrónico
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'juanchavezzp@unicauca.edu.co',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Campo Contraseña
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: '*************',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Línea decorativa blanca
        Center(
          child: Container(
            width: 60,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Botón de Inicio de Sesión
        PrimaryButton(
          text: 'Inicio de Sesión',
          onPressed: onLoginPressed,
        ),
      ],
    );
  }
}