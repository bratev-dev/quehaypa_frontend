import 'package:flutter/material.dart';

import '../organisms/login_hero_header.dart';
import '../molecules/login_form.dart';

class LoginTemplate extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLoginPressed;

  const LoginTemplate({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        const LoginHeroHeader(),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 32.0,
                bottom: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.45),
                  LoginForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    obscurePassword: obscurePassword,
                    onTogglePassword: onTogglePassword,
                    onLoginPressed: onLoginPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
