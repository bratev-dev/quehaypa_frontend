import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preferences/presentation/interests_colors.dart';
import '../../../preferences/presentation/templates/interests_template.dart';
import '../atoms/app_snackbar.dart';
import '../controllers/authentication_controller.dart';
import '../controllers/register_controller.dart';
import '../controllers/register_state.dart';
import '../organisms/interests_selection_form.dart';
import '../organisms/personal_details_form.dart';
import '../organisms/role_selection_form.dart';
import '../templates/personal_details_template.dart';
import '../templates/role_selection_template.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  Future<void> _back(WidgetRef ref) async {
    final state = ref.read(registerControllerProvider);
    if (state.status == RegisterStatus.loading ||
        state.status == RegisterStatus.success) {
      return;
    }
    if (state.currentStep == RegisterStep.roleSelection) {
      final authentication = ref.read(
        authenticationControllerProvider.notifier,
      );
      await authentication.cancelRegistration();
    } else {
      ref.read(registerControllerProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);
    ref.listen(registerControllerProvider, (previous, next) {
      if (next.status == RegisterStatus.success &&
          previous?.status != RegisterStatus.success) {
        ref
            .read(authenticationControllerProvider.notifier)
            .finishRegistration();
      } else if (next.status == RegisterStatus.error &&
          next.errorMessage != null) {
        AppSnackbar.show(
          context,
          message: next.errorMessage!,
          type: SnackbarType.error,
        );
      }
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _back(ref);
        }
      },
      child: Scaffold(
        backgroundColor: state.currentStep == RegisterStep.interests
            ? interestsYellow
            : const Color(0xFF0A47ED),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: state.currentStep == RegisterStep.interests
                  ? interestsBlue
                  : Colors.white,
            ),
            onPressed:
                state.status == RegisterStatus.loading ||
                    state.status == RegisterStatus.success
                ? null
                : () => _back(ref),
          ),
        ),
        body: _body(state),
      ),
    );
  }

  Widget _body(RegisterState state) {
    switch (state.currentStep) {
      case RegisterStep.roleSelection:
        return const RoleSelectionTemplate(
          svgAssetPath: 'assets/images/Hands.svg',
          formContent: RoleSelectionForm(),
        );
      case RegisterStep.personalDetails:
        final organizer = state.selectedRole == UserRole.organizer;
        return PersonalDetailsTemplate(
          svgAssetPath: organizer
              ? 'assets/images/OrganizadorDetails.svg'
              : 'assets/images/UsuarioDetails.svg',
          svgTopFactor: organizer ? 0.09 : 0.02,
          svgWidthFactor: 1,
          svgRightPosition: 0,
          formContent: const PersonalDetailsForm(),
        );
      case RegisterStep.interests:
        return const InterestsTemplate(content: InterestsSelectionForm());
    }
  }
}
