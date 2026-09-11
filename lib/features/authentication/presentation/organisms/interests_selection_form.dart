import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/app_snackbar.dart'; // <-- Importamos nuestro átomo de SnackBar unificado
import '../atoms/interest_chip.dart';
import '../controllers/register_controller.dart';

class InterestsSelectionForm extends ConsumerWidget {
  const InterestsSelectionForm({super.key});

  // Lista simulada de intereses disponibles en la plataforma
  final List<String> _availableInterests = const [
    'Tecnología',
    'Música',
    'Deportes',
    'Arte',
    'Cine',
    'Gastronomía',
    'Lectura',
    'Viajes',
    'Fotografía',
    'Emprendimiento',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerControllerProvider);
    final selectedInterests = registerState.selectedInterests;
    final bool canProceed = selectedInterests.length >= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¿Qué te apasiona?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona al menos 4 intereses (${selectedInterests.length}/4)',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          alignment: WrapAlignment.center,
          children: _availableInterests.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            return InterestChip(
              label: interest,
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(registerControllerProvider.notifier)
                    .toggleInterest(interest);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            if (!canProceed) {
              AppSnackbar.show(
                context,
                'Por favor selecciona al menos 4 intereses para continuar.',
              );
              return;
            }

            ref
                .read(registerControllerProvider.notifier)
                .completeRegistration();
          },
          child: const Text(
            'Finalizar Registro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
