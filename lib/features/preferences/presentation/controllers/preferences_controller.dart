import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failtures.dart';
import 'preferences_providers.dart';
import 'preferences_state.dart';

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, PreferencesState>(
        PreferencesController.new);

/// Controller del catalogo real (GET /interests) + mis preferencias.
/// La Page muestra Loading/Success/Error segun Guia 14.
class PreferencesController extends Notifier<PreferencesState> {
  @override
  PreferencesState build() => const PreferencesState();

  Future<void> loadCatalog() async {
    state = state.copyWith(status: PreferencesStatus.loading);
    try {
      final interests = await ref.read(getInterestsUseCaseProvider)();
      state = state.copyWith(
        status: PreferencesStatus.success,
        catalog: interests.map((e) => e.name).toList(),
      );
    } on Failure catch (e) {
      state = state.copyWith(
        status: PreferencesStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: PreferencesStatus.error,
        errorMessage: 'No fue posible cargar intereses: $e',
      );
    }
  }

  Future<void> loadMine() async {
    try {
      final mine = await ref.read(getMyPreferencesUseCaseProvider)();
      state = state.copyWith(mine: mine);
    } catch (_) {
      // Best-effort: el dashboard sigue con mocks si falla.
    }
  }
}
