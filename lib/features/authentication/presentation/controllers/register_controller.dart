import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failtures.dart';
import '../../domain/entities/auth_session.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import 'register_providers.dart';
import 'register_state.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

class RegisterController extends Notifier<RegisterState> {
  bool _registrationSaved = false;
  @override
  RegisterState build() {
    return const RegisterState();
  }

  void startRegistration(AuthSession session) {
    _registrationSaved = false;
    state = RegisterState(
      email: session.email,
      username: session.username,
      name: session.firstName,
      lastname: session.lastName,
    );
  }

  void startCancellation() {
    state = state.copyWith(status: RegisterStatus.loading);
  }

  void reportCompletionError([String? message]) {
    state = state.copyWith(
      status: RegisterStatus.error,
      errorMessage:
          message ?? 'No fue posible finalizar tu sesión. Inténtalo de nuevo.',
    );
  }

  void selectRole(UserRole role) {
    state = state.copyWith(
      selectedRole: role,
      currentStep: RegisterStep.personalDetails,
      errorMessage: null,
    );
  }

  void savePersonalDetails({
    required String name,
    required String lastname,
    required String username,
    required String birthDate,
    String? cc,
  }) {
    final isOrganizer = state.selectedRole == UserRole.organizer;

    state = state.copyWith(
      name: name,
      lastname: lastname,
      username: username,
      birthDate: birthDate,
      cc: cc ?? '',
      currentStep: isOrganizer
          ? RegisterStep.personalDetails
          : RegisterStep.interests,
      errorMessage: null,
    );

    // Organizador no tiene paso de intereses: dispara el registro directo
    // sin tocar la UI (la UX sigue intacta).
    if (isOrganizer) {
      // ignore: unawaited_futures
      completeRegistration();
    }
  }

  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(state.selectedInterests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }
    state = state.copyWith(selectedInterests: currentInterests);
  }

  void previousStep() {
    switch (state.currentStep) {
      case RegisterStep.roleSelection:
        break;
      case RegisterStep.personalDetails:
        state = state.copyWith(currentStep: RegisterStep.roleSelection);
        break;
      case RegisterStep.interests:
        state = state.copyWith(currentStep: RegisterStep.personalDetails);
        break;
    }
  }

  Future<void> completeRegistration() async {
    if (state.status == RegisterStatus.loading) return;
    if (_registrationSaved) {
      state = state.copyWith(status: RegisterStatus.success);
      return;
    }
    state = state.copyWith(status: RegisterStatus.loading, errorMessage: null);

    try {
      // La identidad ya se creó en Keycloak desde el vídeo.
      // Perfil de negocio (sin password, Bearer por interceptor).
      //    El rol solo ramifica el endpoint; la autoridad es back/Keycloak.
      //    Si el sync devuelve 409 "otro tipo de usuario", no reintentar
      //    con el otro endpoint: mostrar el mensaje tal cual.
      if (state.selectedRole == UserRole.organizer) {
        final useCase = ref.read(syncOrganizerUseCaseProvider);

        try {
          await useCase(
            SyncOrganizerParams(
              username: state.username,
              firstName: state.name,
              lastName: state.lastname,
              email: state.email,
              identificationDocument: state.cc,
            ),
          );
        } on Failure catch (e) {
          throw _StepFailure('No fue posible crear tu perfil: ${e.message}');
        }
      } else {
        final useCase = ref.read(syncProfileUseCaseProvider);

        try {
          await useCase(
            SyncProfileParams(
              username: state.username,
              firstName: state.name,
              lastName: state.lastname,
              email: state.email,
              birthDate: _parseBirthDate(state.birthDate),
            ),
          );
        } on Failure catch (e) {
          throw _StepFailure('No fue posible crear tu perfil: ${e.message}');
        }

        // 3. Intereses (PUT /api/v1/preferences/me, Bearer por interceptor).
        //    Solo usuario regular: el back rechaza organizadores.
        //    Si falla, el perfil sigue pendiente y el sync idempotente
        //    permite reintentar antes de finalizar en el backend.
        if (state.selectedInterests.isNotEmpty) {
          late final List<String> saved;
          try {
            saved = await ref.read(saveMyPreferencesUseCaseProvider)(
              List<String>.from(state.selectedInterests),
            );
          } on Failure catch (e) {
            throw _StepFailure(
              'Tu cuenta se creó pero no fue posible guardar tus intereses: ${e.message}',
            );
          }
          // Precarga las categorías mientras el dashboard consulta su feed.
          try {
            ref
                .read(dashboardControllerProvider.notifier)
                .setUserInterests(saved);
          } catch (_) {
            // El dashboard aún no está montado: se hidratará al entrar.
          }
        }
      }

      _registrationSaved = true;
      state = state.copyWith(status: RegisterStatus.success);
    } on _StepFailure catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.message,
      );
    } on Failure catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage:
            'No fue posible completar el registro. Inténtalo de nuevo.',
      );
    }
  }

  /// La UX manda "DD/MM/YYYY" (o "DD/MM/YY"). El back espera ISO yyyy-MM-dd.
  DateTime? _parseBirthDate(String raw) {
    final parts = raw.split('/');

    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    if (year < 100) {
      year += year <= 30 ? 2000 : 1900;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

/// Error con contexto de paso para el registro estricto: indica si falló
/// el perfil (sync) o los intereses (PUT /preferences/me), porque el
/// mensaje crudo del servidor no lo distingue.
class _StepFailure implements Exception {
  final String message;

  const _StepFailure(this.message);

  @override
  String toString() => message;
}
