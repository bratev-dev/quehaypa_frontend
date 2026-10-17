import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../authentication/presentation/controllers/authentication_state.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../../organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

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
        if (kDebugMode) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(navigationIndexProvider.notifier).setIndex(0);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OrganizerDashboardPage(preview: true),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Vista previa: organizador'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}
