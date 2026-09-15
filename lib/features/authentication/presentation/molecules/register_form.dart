import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import '../atoms/custom_text_field.dart';
import '../atoms/primary_button.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode? emailFocusNode;
  final FocusNode? passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onRegisterPressed;
  final VoidCallback onLoginRedirectPressed;

  const RegisterForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.emailFocusNode,
    this.passwordFocusNode,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.onRegisterPressed,
    required this.onLoginRedirectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El fondo de esta pantalla es azul, así que el borde en foco va amarillo.
        // Campo Correo Electrónico
        CustomTextField(
          controller: emailController,
          focusNode: emailFocusNode,
          hintText: 'juanchavezzp@unicauca.edu.co',
          keyboardType: TextInputType.emailAddress,
          focusedBorderColor: AppColors.inputFocusOnBlue,
        ),
        const SizedBox(height: 16),

        // Campo Contraseña
        CustomTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          hintText: '*************',
          obscureText: obscurePassword,
          focusedBorderColor: AppColors.inputFocusOnBlue,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: onTogglePassword,
          ),
        ),
        const SizedBox(height: 12),

        // Checkbox de Términos y Condiciones
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: const Color(0xFFFCD413),
                checkColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFFCD413), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Acepto los términos y condiciones',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Botón de Registro
        PrimaryButton(
          text: 'Registrarse',
          backgroundColor: const Color(0xFFFFD600),
          textColor: Colors.black87,
          onPressed: onRegisterPressed,
        ),
        const SizedBox(height: 16),

        // Enlace inferior: ¿Ya tienes una cuenta? Iniciar sesión
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Ya tienes una cuenta? ',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            GestureDetector(
              onTap: onLoginRedirectPressed,
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: Colors.white,
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
