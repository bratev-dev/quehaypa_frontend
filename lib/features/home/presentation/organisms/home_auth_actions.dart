import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../authentication/presentation/controllers/authentication_state.dart';

class HomeAuthActions extends ConsumerWidget {
  const HomeAuthActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading =
        ref.watch(authenticationControllerProvider).status ==
        AuthenticationStatus.loading;
    final controller = ref.read(authenticationControllerProvider.notifier);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: loading ? null : controller.login,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A47ED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Iniciar Sesión',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: loading ? null : controller.register,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Registrarse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
