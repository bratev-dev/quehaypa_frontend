import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preferences/presentation/controllers/preferences_controller.dart';
import '../../../preferences/presentation/controllers/preferences_state.dart';
import '../controllers/register_state.dart';
import '../../../preferences/presentation/interests_colors.dart';
import '../../../preferences/presentation/organisms/interest_options.dart';
import '../atoms/app_snackbar.dart';
import '../controllers/register_controller.dart';

class InterestsSelectionForm extends ConsumerStatefulWidget {
  const InterestsSelectionForm({super.key});

  @override
  ConsumerState<InterestsSelectionForm> createState() =>
      _InterestsSelectionFormState();
}

class _InterestsSelectionFormState
    extends ConsumerState<InterestsSelectionForm> {
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

    final available = prefsState.catalog;
    final catalogReady =
        prefsState.status == PreferencesStatus.success && available.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¿Qué te apasiona?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: interestsBlue,
          ),
          textAlign: TextAlign.center,
        ),
        if (prefsState.status == PreferencesStatus.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: interestsBlue),
            ),
          ),
        if (prefsState.status == PreferencesStatus.error)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'No pudimos cargar el catálogo de intereses. Reintenta.',
                    style: TextStyle(color: interestsBlue, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: interestsBlue,
                    size: 18,
                  ),
                  tooltip: 'Reintentar',
                  onPressed: () => ref
                      .read(preferencesControllerProvider.notifier)
                      .loadCatalog(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (catalogReady)
          InterestOptions(
            catalog: available,
            selected: selectedInterests,
            onToggle: (interest) => ref
                .read(registerControllerProvider.notifier)
                .toggleInterest(interest),
          ),
        if (prefsState.status == PreferencesStatus.success && available.isEmpty)
          const Text(
            'No hay intereses disponibles por ahora.',
            textAlign: TextAlign.center,
            style: TextStyle(color: interestsBlue),
          ),
        const SizedBox(height: 14),
        Text(
          'Selecciona al menos 4 intereses (${selectedInterests.length}/4)',
          style: const TextStyle(fontSize: 14, color: interestsBlue),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Center(
          child: SizedBox(
            width: 259,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: interestsBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(57),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed:
                  !catalogReady ||
                      registerState.status == RegisterStatus.loading
                  ? null
                  : () {
                      if (!canProceed) {
                        AppSnackbar.show(
                          context,
                          message:
                              'Selecciona al menos 4 intereses para continuar.',
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
          ),
        ),
      ],
    );
  }
}
