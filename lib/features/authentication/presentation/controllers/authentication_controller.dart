import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../../../core/security/session_events_provider.dart';
import '../../../../core/security/security_providers.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';
import 'authentication_providers.dart';
import 'authentication_state.dart';
import 'register_providers.dart';
import 'register_controller.dart';
import 'register_state.dart';

final authenticationControllerProvider =
    NotifierProvider<AuthenticationController, AuthenticationState>(
      AuthenticationController.new,
    );

class AuthenticationController extends Notifier<AuthenticationState> {
  late final LoginUseCase _loginUseCase;
  late final RestoreSessionUseCase _restoreSessionUseCase;
  late final LogoutUseCase _logoutUseCase;

  @override
  AuthenticationState build() {
    _loginUseCase = ref.read(loginUseCaseProvider);
    _restoreSessionUseCase = ref.read(restoreSessionUseCaseProvider);
    _logoutUseCase = ref.read(logoutUseCaseProvider);

    ref.listen<AsyncValue<void>>(sessionInvalidatedProvider, (_, next) {
      next.whenData((_) {
        ref.invalidate(dashboardControllerProvider);
        state = const AuthenticationState(
          status: AuthenticationStatus.unauthenticated,
        );
      });
    });

    return const AuthenticationState.initial();
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthenticationStatus.loading);

    try {
      final session = await _restoreSessionUseCase();

      if (session == null) {
        state = state.copyWith(status: AuthenticationStatus.unauthenticated);
        return;
      }

      if (await _registrationPending()) {
        ref
            .read(registerControllerProvider.notifier)
            .startRegistration(session);
        state = AuthenticationState(
          status: AuthenticationStatus.registrationRequired,
          session: session,
        );
        return;
      }

      state = state.copyWith(
        status: AuthenticationStatus.authenticated,
        session: session,
        isOrganizer: await _resolveProfileBestEffort(),
      );
    } catch (e) {
      state = state.copyWith(status: AuthenticationStatus.unauthenticated);
    }
  }

  Future<void> login({String? loginHint}) async {
    if (state.status == AuthenticationStatus.loading) return;
    state = state.copyWith(
      status: AuthenticationStatus.loading,
      errorMessage: null,
    );

    try {
      final AuthSession session = await _loginUseCase(loginHint: loginHint);

      if (await _registrationPending()) {
        ref
            .read(registerControllerProvider.notifier)
            .startRegistration(session);
        state = AuthenticationState(
          status: AuthenticationStatus.registrationRequired,
          session: session,
        );
        return;
      }

      // Guía §10: tras el token, resolver el perfil de negocio (quién soy).
      // El estado remoto ya confirmó que el registro está completo.
      // Esta consulta solo hidrata datos adicionales de la cuenta.
      final isOrganizer = await _resolveProfileBestEffort();

      state = state.copyWith(
        status: AuthenticationStatus.authenticated,
        session: session,
        isOrganizer: isOrganizer,
      );
    } on AuthenticationCancelledException {
      // El usuario cerró la pantalla de Keycloak (ej. botón atrás) antes de
      // terminar. No es un error: vuelve al vídeo en silencio.
      state = state.copyWith(status: AuthenticationStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthenticationStatus.error,
        errorMessage: e is Failure
            ? e.message
            : AppErrorHandler.getFriendlyMessage(e),
      );
    }
  }

  Future<void> register() async {
    if (state.status == AuthenticationStatus.loading) return;
    state = const AuthenticationState(status: AuthenticationStatus.loading);
    try {
      final session = await ref.read(registerWithKeycloakUseCaseProvider)();
      final pending = await _registrationPending();
      if (pending) {
        ref
            .read(registerControllerProvider.notifier)
            .startRegistration(session);
      }
      state = AuthenticationState(
        status: pending
            ? AuthenticationStatus.registrationRequired
            : AuthenticationStatus.authenticated,
        session: session,
        isOrganizer: !pending && await _resolveProfileBestEffort(),
      );
    } on AuthenticationCancelledException {
      state = const AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
      );
    } catch (e) {
      state = AuthenticationState(
        status: AuthenticationStatus.error,
        errorMessage: e is Failure
            ? e.message
            : AppErrorHandler.getFriendlyMessage(e),
      );
    }
  }

  /// El perfil y sus preferencias ya se guardaron; habilita la navegación privada.
  Future<void> finishRegistration() async {
    if (state.status != AuthenticationStatus.registrationRequired) return;
    try {
      await ref.read(manageRegistrationUseCaseProvider).complete();
    } on Failure catch (e) {
      ref
          .read(registerControllerProvider.notifier)
          .reportCompletionError(e.message);
      return;
    } catch (_) {
      ref.read(registerControllerProvider.notifier).reportCompletionError();
      return;
    }
    var session = state.session;
    try {
      session = await ref.read(refreshSessionUseCaseProvider)();
    } catch (_) {
      // El interceptor podrá volver a intentar renovar la sesión.
    }
    try {
      await ref.read(tokenManagerProvider).setRegistrationPending(false);
    } catch (_) {
      // Permite reintentar sin perder el perfil ya guardado.
      ref.read(registerControllerProvider.notifier).reportCompletionError();
      return;
    }
    if (state.status != AuthenticationStatus.registrationRequired) return;
    state = AuthenticationState(
      status: AuthenticationStatus.authenticated,
      session: session,
      isOrganizer:
          ref.read(registerControllerProvider).selectedRole ==
          UserRole.organizer,
    );
  }

  Future<bool> _registrationPending() async {
    final pending = await ref.read(manageRegistrationUseCaseProvider).begin();
    await ref.read(tokenManagerProvider).setRegistrationPending(pending);
    return pending;
  }

  /// Renueva los claims después de editar el perfil, sin abrir el navegador.
  Future<bool> refreshProfileSession() async {
    try {
      final session = await ref.read(refreshSessionUseCaseProvider)();
      state = state.copyWith(session: session);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelRegistration() async {
    final register = ref.read(registerControllerProvider.notifier);
    register.startCancellation();
    try {
      await ref.read(manageRegistrationUseCaseProvider).cancel();
    } on Failure catch (e) {
      register.reportCompletionError(
        'No se pudo cancelar el registro: ${e.message}',
      );
      return false;
    } catch (_) {
      register.reportCompletionError(
        'No se pudo cancelar el registro. Vuelve a intentarlo.',
      );
      return false;
    }
    await logout();
    ref.invalidate(registerControllerProvider);
    return true;
  }

  Future<bool> logout() async {
    try {
      await _logoutUseCase();
      state = const AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
      );
      return true;
    } catch (e) {
      // El repositorio elimina los tokens locales incluso si Keycloak falla.
      state = AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
        errorMessage: AppErrorHandler.getFriendlyMessage(e),
      );
      return false;
    } finally {
      ref.invalidate(dashboardControllerProvider);
    }
  }

  /// Hidrata preferencias tras verificar el estado completo en el backend.
  Future<bool> _resolveProfileBestEffort() async {
    try {
      await ref.read(userRemoteDataSourceProvider).getProfile();
      try {
        final prefs = await ref.read(getMyPreferencesUseCaseProvider)();
        try {
          ref
              .read(dashboardControllerProvider.notifier)
              .setUserInterests(prefs);
        } catch (_) {
          // Dashboard no montado aun: se hidrata al entrar.
        }
      } catch (_) {
        // El dashboard consultará su feed sin intereses precargados.
      }
      return false;
    } catch (_) {
      // No es regular (404/403) -> probar organizador.
    }
    try {
      await ref.read(organizerRemoteDataSourceProvider).getProfile();
      return true;
    } catch (_) {
      // La carga adicional no cambia el estado confirmado por el backend.
      return false;
    }
  }
}
