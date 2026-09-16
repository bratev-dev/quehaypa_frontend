import 'package:flutter/material.dart';

import '../organisms/register_hero_header.dart';
import '../molecules/register_form.dart';

class RegisterTemplate extends StatelessWidget {
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

  const RegisterTemplate({
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
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        const RegisterHeroHeader(),
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
                  RegisterForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    emailFocusNode: emailFocusNode,
                    passwordFocusNode: passwordFocusNode,
                    obscurePassword: obscurePassword,
                    onTogglePassword: onTogglePassword,
                    termsAccepted: termsAccepted,
                    onTermsChanged: onTermsChanged,
                    onRegisterPressed: onRegisterPressed,
                    onLoginRedirectPressed: onLoginRedirectPressed,
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
