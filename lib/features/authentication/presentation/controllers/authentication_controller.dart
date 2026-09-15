import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error_handler.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/session_events_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/restore_session_use_case.dart';
import 'authentication_providers.dart';
import 'authentication_state.dart';

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

      state = state.copyWith(
        status: AuthenticationStatus.authenticated,
        session: session,
      );
    } catch (e) {
      state = state.copyWith(status: AuthenticationStatus.unauthenticated);
    }
  }

  Future<void> login({String? loginHint}) async {
    state = state.copyWith(
      status: AuthenticationStatus.loading,
      errorMessage: null,
    );

    try {
      final AuthSession session = await _loginUseCase(loginHint: loginHint);

      state = state.copyWith(
        status: AuthenticationStatus.authenticated,
        session: session,
      );
    } on AuthenticationCancelledException {
      // El usuario cerró la pantalla de Keycloak (ej. botón atrás) antes de
      // terminar. No es un error: solo lo devolvemos al login en silencio.
      state = state.copyWith(status: AuthenticationStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthenticationStatus.error,
        errorMessage: AppErrorHandler.getFriendlyMessage(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _logoutUseCase();

      state = const AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthenticationStatus.error,
        errorMessage: AppErrorHandler.getFriendlyMessage(e),
      );
    }
  }
}
