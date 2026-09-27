import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/authentication/presentation/organisms/personal_details_form.dart';
import 'package:frontend/features/authentication/presentation/organisms/role_selection_form.dart';
import 'package:frontend/features/authentication/presentation/pages/register_page.dart';

import '../../../../helpers/widget_finders.dart';

class _ScriptedRegisterController extends RegisterController {
  final RegisterState initial;
  _ScriptedRegisterController(this.initial);
  @override
  RegisterState build() => initial;
  void emit(RegisterState next) => state = next;
}

class _AuthController extends AuthenticationController {
  bool finished = false;
  bool loggedOut = false;
  @override
  AuthenticationState build() => const AuthenticationState(
    status: AuthenticationStatus.registrationRequired,
  );
  @override
  Future<void> finishRegistration() async {
    finished = true;
  }

  @override
  Future<bool> logout() async {
    loggedOut = true;
    return true;
  }

  @override
  Future<bool> cancelRegistration() async {
    loggedOut = true;
    return true;
  }
}

void main() {
  late ProviderContainer container;
  late _AuthController auth;

  Future<void> pumpRegister(
    WidgetTester tester, {
    RegisterState initial = const RegisterState(),
  }) async {
    useTallScreen(tester);
    auth = _AuthController();
    container = ProviderContainer(
      overrides: [
        registerControllerProvider.overrideWith(
          () => _ScriptedRegisterController(initial),
        ),
        authenticationControllerProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RegisterPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('empieza en rol sin formulario de correo ni contraseña', (
    tester,
  ) async {
    await pumpRegister(tester);
    expect(find.byType(RoleSelectionForm), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('datos personales conserva el formulario y vuelve a rol', (
    tester,
  ) async {
    await pumpRegister(
      tester,
      initial: const RegisterState(
        currentStep: RegisterStep.personalDetails,
        selectedRole: UserRole.organizer,
        name: 'Ana',
        lastname: 'Ruiz',
        username: 'ana.keycloak',
      ),
    );
    expect(find.byType(PersonalDetailsForm), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Ruiz'), findsOneWidget);
    expect(find.text('ana.keycloak'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(
      container.read(registerControllerProvider).currentStep,
      RegisterStep.roleSelection,
    );
  });

  testWidgets('atrás desde rol cierra la sesión pendiente', (tester) async {
    await pumpRegister(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(auth.loggedOut, isTrue);
  });

  testWidgets('atrás del sistema recorre los pasos', (tester) async {
    await pumpRegister(
      tester,
      initial: const RegisterState(currentStep: RegisterStep.personalDetails),
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      container.read(registerControllerProvider).currentStep,
      RegisterStep.roleSelection,
    );
  });

  testWidgets('el éxito habilita el dashboard mediante autenticación', (
    tester,
  ) async {
    await pumpRegister(tester);
    final controller = container.read(
      registerControllerProvider.notifier,
    ) as _ScriptedRegisterController;
    controller.emit(const RegisterState(status: RegisterStatus.success));
    await tester.pump();
    expect(auth.finished, isTrue);
  });

  testWidgets('los errores reales del perfil siguen visibles', (tester) async {
    await pumpRegister(tester);
    final controller = container.read(
      registerControllerProvider.notifier,
    ) as _ScriptedRegisterController;
    controller.emit(
      const RegisterState(
        status: RegisterStatus.error,
        errorMessage: 'No fue posible guardar tu perfil',
      ),
    );
    await tester.pump();
    expect(find.text('No fue posible guardar tu perfil'), findsOneWidget);
    expect(auth.finished, isFalse);
  });
}
