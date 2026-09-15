import 'package:flutter/material.dart';

import '../atoms/custom_text_field.dart';
import '../atoms/primary_button.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode? emailFocusNode;
  final VoidCallback? onLoginPressed;
  final VoidCallback onRegisterPressed;

  const LoginForm({
    super.key,
    required this.emailController,
    this.emailFocusNode,
    required this.onLoginPressed,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo Correo Electrónico (Opcional para identificar o pre-llenar en Keycloak)
        // El fondo de esta pantalla es amarillo, así que el borde en foco va azul.
        CustomTextField(
          controller: emailController,
          focusNode: emailFocusNode,
          hintText: 'juanchavezzp@unicauca.edu.co',
          keyboardType: TextInputType.emailAddress,
          focusedBorderColor: const Color(0xFF0038FF),
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

        // Botón de Inicio de Sesión (Lanza el flujo de Keycloak)
        PrimaryButton(text: 'Iniciar Sesión', onPressed: onLoginPressed),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Todavía no tienes una cuenta? ',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            GestureDetector(
              onTap: onRegisterPressed,
              child: const Text(
                'Regístrate',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
