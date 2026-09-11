import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(
      name: name,
      lastname: lastname,
      username: username,
      birthDate: birthDate,
      cc: cc ?? '',
      currentStep: state.selectedRole == UserRole.user
          ? RegisterStep.interests
          : RegisterStep.credentials, // O puedes disparar el registro directamente si es organizador
      errorMessage: null,
    );
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
      // TODO: Aquí integrarás la llamada a tu caso de uso de registro enviando `state`
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(status: RegisterStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
