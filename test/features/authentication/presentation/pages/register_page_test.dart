import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/route_paths.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/authentication/presentation/organisms/personal_details_form.dart';
import 'package:frontend/features/authentication/presentation/pages/register_page.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/widget_finders.dart';

const _emailHint = 'juanchavezzp@unicauca.edu.co';
const _passwordHint = '*************';

/// Controlador que arranca en un estado dado y permite emitir otros, para
/// probar cómo reacciona la página sin recorrer todo el registro.
class _ScriptedRegisterController extends RegisterController {
  final RegisterState initial;

  _ScriptedRegisterController(this.initial);

  @override
  RegisterState build() => initial;

  void emit(RegisterState next) => state = next;
}

/// Validaciones del paso de credenciales del registro (HU-1.1).
void main() {
  late ProviderContainer container;

  Future<void> pumpRegister(
    WidgetTester tester, {
    RegisterState? initial,
  }) async {
    useTallScreen(tester);
    container = ProviderContainer(
      overrides: [
        if (initial != null)
          registerControllerProvider.overrideWith(
            () => _ScriptedRegisterController(initial),
          ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: RoutePaths.register,
      routes: [
        GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const RegisterPage(),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (_, _) => const Text('pantalla de login'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  Future<void> fill(
    WidgetTester tester, {
    String email = 'ana@test.com',
    String password = 'secreta1',
    bool acceptTerms = true,
  }) async {
    await tester.enterText(fieldWithHint(_emailHint), email);
    await tester.enterText(fieldWithHint(_passwordHint), password);
    if (acceptTerms) await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Registrarse'));
    await tester.pump();
  }

  RegisterState state() => container.read(registerControllerProvider);

  final invalidos = <String, (String, String, bool, String)>{
    'sin correo': (
      '',
      'secreta1',
      true,
      'Por favor ingresa tu correo electrónico.',
    ),
    'correo mal formado': (
      'ana@test',
      'secreta1',
      true,
      'El formato del correo electrónico no es válido.',
    ),
    'sin contraseña': (
      'ana@test.com',
      '',
      true,
      'Por favor ingresa tu contraseña.',
    ),
    'contraseña corta': (
      'ana@test.com',
      '12345',
      true,
      'La contraseña debe tener al menos 6 caracteres.',
    ),
    'sin aceptar términos': (
      'ana@test.com',
      'secreta1',
      false,
      'Debes aceptar los términos y condiciones.',
    ),
  };

  invalidos.forEach((caso, datos) {
    testWidgets('no avanza $caso', (tester) async {
      await pumpRegister(tester);
      await fill(
        tester,
        email: datos.$1,
        password: datos.$2,
        acceptTerms: datos.$3,
      );

      await submit(tester);

      expect(find.text(datos.$4), findsWidgets);
      expect(state().currentStep, RegisterStep.credentials);
    });
  });

  testWidgets('con datos válidos guarda las credenciales y pasa a elegir rol', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fill(tester, email: '  ana@test.com ');

    await submit(tester);

    expect(state().email, 'ana@test.com');
    expect(state().currentStep, RegisterStep.roleSelection);
  });

  testWidgets(
    'avisa al salir del correo o de la contraseña con datos inválidos',
    (tester) async {
      await pumpRegister(tester);

      await tester.tap(fieldWithHint(_emailHint));
      await tester.enterText(fieldWithHint(_emailHint), 'ana@');
      await tester.tap(fieldWithHint(_passwordHint));
      await tester.pump();
      expect(
        find.text('El formato del correo electrónico no es válido.'),
        findsOneWidget,
      );

      await tester.enterText(fieldWithHint(_passwordHint), '123');
      await tester.tap(fieldWithHint(_emailHint));
      await tester.pump();
      expect(
        find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('el ícono del ojo muestra y oculta la contraseña', (
    tester,
  ) async {
    await pumpRegister(tester);
    bool obscured() =>
        tester.widget<TextField>(fieldWithHint(_passwordHint)).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  testWidgets('el enlace "Iniciar sesión" vuelve al login', (tester) async {
    await pumpRegister(tester);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla de login'), findsOneWidget);
  });

  testWidgets('en datos personales muestra el formulario y la flecha regresa', (
    tester,
  ) async {
    await pumpRegister(
      tester,
      initial: const RegisterState(
        currentStep: RegisterStep.personalDetails,
        selectedRole: UserRole.organizer,
      ),
    );
    expect(find.byType(PersonalDetailsForm), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(state().currentStep, RegisterStep.roleSelection);
  });

  testWidgets('informa el éxito y los errores del registro', (tester) async {
    await pumpRegister(tester, initial: const RegisterState());
    final controller = container.read(
      registerControllerProvider.notifier,
    ) as _ScriptedRegisterController;

    controller.emit(const RegisterState(status: RegisterStatus.success));
    await tester.pump();
    expect(find.text('¡Registro completado con éxito!'), findsOneWidget);

    controller.emit(
      const RegisterState(
        status: RegisterStatus.error,
        errorMessage: 'El correo ya existe',
      ),
    );
    await tester.pump();
    expect(find.text('El correo ya existe'), findsOneWidget);
  });
}
