import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preferences/presentation/controllers/preferences_controller.dart';
import '../../../preferences/presentation/controllers/preferences_state.dart';
import '../atoms/app_snackbar.dart';
import '../atoms/interest_chip.dart';
import '../controllers/register_controller.dart';

class InterestsSelectionForm extends ConsumerStatefulWidget {
  const InterestsSelectionForm({super.key});

  @override
  ConsumerState<InterestsSelectionForm> createState() =>
      _InterestsSelectionFormState();
}

class _InterestsSelectionFormState
    extends ConsumerState<InterestsSelectionForm> {
  static const List<String> kFallbackInterests = [
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
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(preferencesControllerProvider.notifier).loadCatalog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final selectedInterests = registerState.selectedInterests;
    final bool canProceed = selectedInterests.length >= 4;
    final prefsState = ref.watch(preferencesControllerProvider);

    final List<String> available = prefsState.catalog.isNotEmpty
        ? prefsState.catalog
        : kFallbackInterests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Que te apasiona?',
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
        if (prefsState.status == PreferencesStatus.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (prefsState.status == PreferencesStatus.error)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Sin conexion al catalogo, usando lista local.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: () => ref
                      .read(preferencesControllerProvider.notifier)
                      .loadCatalog(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          alignment: WrapAlignment.center,
          children: available.map((interest) {
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
                message: 'Selecciona al menos 4 intereses para continuar.',
                type: SnackbarType.info,
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
