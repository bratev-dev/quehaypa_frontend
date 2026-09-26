import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../preferences/presentation/interests_colors.dart';
import '../../../preferences/presentation/templates/interests_template.dart';
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

  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmailOnBlur();
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _validatePasswordOnBlur();
      }
    });
  }

  void _validateEmailOnBlur() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
      AppSnackbar.show(
        context,
        message: 'El formato del correo electrónico no es válido.',
        type: SnackbarType.info,
      );
    }
  }

  void _validatePasswordOnBlur() {
    final password = _passwordController.text;

    if (password.isNotEmpty && password.length < 6) {
      AppSnackbar.show(
        context,
        message: 'La contraseña debe tener al menos 6 caracteres.',
        type: SnackbarType.info,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    ref.listen(registerControllerProvider, (previous, next) {
      if (next.status == RegisterStatus.success) {
        AppSnackbar.show(
          context,
          message: '¡Registro completado con éxito!',
          type: SnackbarType.success,
        );
        // context.go(RoutePaths.dashboard);
      } else if (next.status == RegisterStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(
          context,
          message: next.errorMessage!,
          type: SnackbarType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: registerState.currentStep == RegisterStep.interests
          ? interestsYellow
          : const Color(0xFF0A47ED),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: registerState.currentStep != RegisterStep.credentials
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: registerState.currentStep == RegisterStep.interests
                      ? interestsBlue
                      : Colors.white,
                ),
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
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
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
                message: 'Por favor ingresa tu correo electrónico.',
                type: SnackbarType.info,
              );
              return;
            }
            if (!emailRegex.hasMatch(email)) {
              AppSnackbar.show(
                context,
                message: 'El formato del correo electrónico no es válido.',
                type: SnackbarType.info,
              );
              return;
            }
            if (password.isEmpty) {
              AppSnackbar.show(
                context,
                message: 'Por favor ingresa tu contraseña.',
                type: SnackbarType.info,
              );
              return;
            }
            if (password.length < 6) {
              AppSnackbar.show(
                context,
                message: 'La contraseña debe tener al menos 6 caracteres.',
                type: SnackbarType.info,
              );
              return;
            }
            if (!_termsAccepted) {
              AppSnackbar.show(
                context,
                message: 'Debes aceptar los términos y condiciones.',
                type: SnackbarType.info,
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
        return const InterestsTemplate(content: InterestsSelectionForm());
    }
  }
}
