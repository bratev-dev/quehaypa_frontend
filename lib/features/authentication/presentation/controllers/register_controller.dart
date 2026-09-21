import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failtures.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import 'authentication_providers.dart';
import 'register_providers.dart';
import 'register_state.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() {
    return const RegisterState();
  }

  void saveCredentials({required String email, required String password}) {
    state = state.copyWith(
      email: email,
      password: password,
      currentStep: RegisterStep.roleSelection,
      errorMessage: null,
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
        state = state.copyWith(currentStep: RegisterStep.credentials);
        break;
      case RegisterStep.personalDetails:
        state = state.copyWith(currentStep: RegisterStep.roleSelection);
        break;
      case RegisterStep.interests:
        state = state.copyWith(currentStep: RegisterStep.personalDetails);
        break;
      case RegisterStep.credentials:
        break;
    }
  }

  Future<void> completeRegistration() async {
    state = state.copyWith(status: RegisterStatus.loading, errorMessage: null);

    try {
      // 1. Identidad en Keycloak (HTML de registro, PKCE). La password se
      //    crea allá y nunca toca el monolito. Si cancela el browser,
      //    error amable y no se intenta el sync.
      try {
        await ref.read(registerWithKeycloakUseCaseProvider)();
      } catch (e) {
        state = state.copyWith(
          status: RegisterStatus.error,
          errorMessage:
              'No fue posible registrarte en Keycloak: ${e.toString().replaceFirst('Exception: ', '')}',
        );
        return;
      }

      // 2. Perfil de negocio (sin password, Bearer por interceptor).
      //    El rol solo ramifica el endpoint; la autoridad es back/Keycloak.
      if (state.selectedRole == UserRole.organizer) {
        final useCase = ref.read(syncOrganizerUseCaseProvider);

        await useCase(
          SyncOrganizerParams(
            username: state.username,
            firstName: state.name,
            lastName: state.lastname,
            email: state.email,
            identificationDocument: state.cc,
          ),
        );
      } else {
        final useCase = ref.read(syncProfileUseCaseProvider);

        await useCase(
          SyncProfileParams(
            username: state.username,
            firstName: state.name,
            lastName: state.lastname,
            email: state.email,
            birthDate: _parseBirthDate(state.birthDate),
          ),
        );

        // 3. Intereses (PUT /api/v1/preferences/me, Bearer por interceptor).
        //    Solo usuario regular: el back rechaza organizadores.
        if (state.selectedInterests.isNotEmpty) {
          final saved = await ref.read(saveMyPreferencesUseCaseProvider)(
            List<String>.from(state.selectedInterests),
          );
          // Hidrata el dashboard para el filtrado local de eventos (QHP-78).
          try {
            ref
                .read(dashboardControllerProvider.notifier)
                .setUserInterests(saved);
          } catch (_) {
            // El dashboard aún no está montado: se hidratará al entrar.
          }
        }
      }

      state = state.copyWith(status: RegisterStatus.success);
    } on Failure catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'No fue posible completar el registro: $e',
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
