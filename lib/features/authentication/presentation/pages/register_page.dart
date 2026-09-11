import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../atoms/app_snackbar.dart';
import '../controllers/register_controller.dart';
import '../controllers/register_state.dart';
import '../organisms/interests_selection_form.dart';
import '../organisms/personal_details_form.dart';
import '../organisms/role_selection_form.dart';
import '../templates/personal_details_template.dart';
import '../templates/register_template.dart';
import '../templates/role_selection_template.dart';

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

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    ref.listen(registerControllerProvider, (previous, next) {
      if (next.status == RegisterStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro completado con éxito!')),
        );
        // context.go(RoutePaths.dashboard);
      } else if (next.status == RegisterStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(context, next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A47ED),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: registerState.currentStep != RegisterStep.credentials
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  ref.read(registerControllerProvider.notifier).previousStep();
                },
              )
            : null,
      ),
      body: _buildCurrentStepBody(registerState, emailRegex),
    );
  }

  Widget _buildCurrentStepBody(RegisterState state, RegExp emailRegex) {
    switch (state.currentStep) {
      case RegisterStep.credentials:
        return RegisterTemplate(
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
              AppSnackbar.show(
                context,
                'Por favor ingresa tu correo electrónico.',
              );
              return;
            }
            if (!emailRegex.hasMatch(email)) {
              AppSnackbar.show(
                context,
                'El formato del correo electrónico no es válido.',
              );
              return;
            }
            if (password.isEmpty) {
              AppSnackbar.show(context, 'Por favor ingresa tu contraseña.');
              return;
            }
            if (password.length < 6) {
              AppSnackbar.show(
                context,
                'La contraseña debe tener al menos 6 caracteres.',
              );
              return;
            }
            if (!_termsAccepted) {
              AppSnackbar.show(
                context,
                'Debes aceptar los términos y condiciones.',
              );
              return;
            }

            ref
                .read(registerControllerProvider.notifier)
                .saveCredentials(email: email, password: password);
          },
          onLoginRedirectPressed: () {
            context.go(RoutePaths.login);
          },
        );

      case RegisterStep.roleSelection:
        return const RoleSelectionTemplate(
          svgAssetPath: 'assets/images/Hands.svg',
          formContent: RoleSelectionForm(),
        );

      case RegisterStep.personalDetails:
        final isOrganizer = state.selectedRole == UserRole.organizer;

        return PersonalDetailsTemplate(
          svgAssetPath: isOrganizer
              ? 'assets/images/OrganizadorDetails.svg'
              : 'assets/images/UsuarioDetails.svg',
          svgTopFactor: isOrganizer ? 0.09 : 0.02,
          svgWidthFactor: isOrganizer ? 1 : 1,
          svgRightPosition: isOrganizer ? 0.0 : 0.0,
          formContent: const PersonalDetailsForm(),
        );

      case RegisterStep.interests:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: const InterestsSelectionForm(),
              ),
            ),
          ),
        );
    }
  }
}
