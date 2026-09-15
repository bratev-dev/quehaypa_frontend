import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../atoms/app_snackbar.dart';
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
  late final FocusNode _emailFocusNode;
  bool _emailHasError = false;

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmailOnBlur();
      }
    });
  }

  /// Valida el formato del correo al perder el foco. Un correo vacío es
  /// válido (es opcional, solo se usa como login_hint). Si el formato es
  /// inválido: muestra el aviso, deshabilita el botón de inicio de sesión
  /// y regresa el foco al campo para forzar la corrección.
  void _validateEmailOnBlur() {
    final email = _emailController.text.trim();
    final isValid = email.isEmpty || _emailRegex.hasMatch(email);

    if (!mounted) return;

    setState(() => _emailHasError = !isValid);

    if (!isValid) {
      AppSnackbar.show(
        context,
        message: 'El formato del correo electrónico no es válido.',
        type: SnackbarType.info,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_emailFocusNode);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationControllerProvider);

    // Escuchamos los cambios de estado para manejar errores con nuestro AppSnackbar unificado
    ref.listen(authenticationControllerProvider, (previous, next) {
      if (next.status == AuthenticationStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(
          context,
          message: next.errorMessage!,
          type: SnackbarType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      body: authenticationState.status == AuthenticationStatus.loading
          ? const SafeArea(
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
            )
          : LoginTemplate(
              emailController: _emailController,
              emailFocusNode: _emailFocusNode,
              onLoginPressed: _emailHasError
                  ? null
                  : () {
                      final email = _emailController.text.trim();

                      // Respaldo por si nunca hubo blur (ej. autocompletado).
                      if (email.isNotEmpty && !_emailRegex.hasMatch(email)) {
                        _validateEmailOnBlur();
                        return;
                      }

                      // Disparamos el login hacia Keycloak, pre-rellenando
                      // el usuario con el correo ya validado (login_hint).
                      ref
                          .read(authenticationControllerProvider.notifier)
                          .login(loginHint: email.isNotEmpty ? email : null);
                    },
              onRegisterPressed: () {
                context.go(RoutePaths.register);
              },
            ),
    );
  }
}
