import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/entities/organizer.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/organizer_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/register_with_keycloak_use_case.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';

class FakeAuthRepository implements AuthenticationRepository {
  bool registerCalled = false;
  bool failRegister = false;

  @override
  Future<AuthSession> register() async {
    registerCalled = true;
    if (failRegister) {
      throw const AuthenticationException('Registro cancelado');
    }
    return const AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      idToken: 'id',
    );
  }

  @override
  Future<AuthSession> login({String? loginHint}) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<AuthSession> refreshSession() => throw UnimplementedError();

  @override
  Future<AuthSession?> restoreSession() => throw UnimplementedError();
}

class FakeUserRepository implements UserRepository {
  SyncProfileParams? lastParams;

  @override
  Future<User> syncProfile(SyncProfileParams params) async {
    lastParams = params;
    return User(
      id: 1,
      username: params.username,
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      birthDate: params.birthDate,
      isActive: true,
    );
  }

  @override
  Future<User> getProfile() => throw UnimplementedError();
}

class FakeOrganizerRepository implements OrganizerRepository {
  SyncOrganizerParams? lastParams;

  @override
  Future<Organizer> syncProfile(SyncOrganizerParams params) async {
    lastParams = params;
    return Organizer(
      id: 7,
      username: params.username,
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      identificationDocument: params.identificationDocument,
      isActive: true,
    );
  }

  @override
  Future<Organizer> getProfile() => throw UnimplementedError();
}

void main() {
  late FakeAuthRepository authRepo;
  late FakeUserRepository userRepo;
  late FakeOrganizerRepository organizerRepo;
  late ProviderContainer container;

  setUp(() {
    authRepo = FakeAuthRepository();
    userRepo = FakeUserRepository();
    organizerRepo = FakeOrganizerRepository();
    container = ProviderContainer(
      overrides: [
        registerWithKeycloakUseCaseProvider.overrideWithValue(
          RegisterWithKeycloakUseCase(authRepo),
        ),
        syncProfileUseCaseProvider.overrideWithValue(
          SyncProfileUseCase(userRepo),
        ),
        syncOrganizerUseCaseProvider.overrideWithValue(
          SyncOrganizerUseCase(organizerRepo),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  RegisterController controller() =>
      container.read(registerControllerProvider.notifier);

  void fillUserBasics() {
    controller().saveCredentials(
      email: 'user@test.com',
      password: 'Secreta123',
    );
    controller().selectRole(UserRole.user);
    controller().savePersonalDetails(
      name: 'User',
      lastname: 'Test',
      username: 'user.test',
      birthDate: '20/05/2000',
    );
  }

  group('ramificación por rol', () {
    test('usuario avanza a intereses sin disparar registro', () {
      fillUserBasics();

      final state = container.read(registerControllerProvider);
      expect(state.currentStep, RegisterStep.interests);
      expect(state.status, RegisterStatus.initial);
      expect(authRepo.registerCalled, isFalse);
    });

    test('organizador dispara el registro automático', () async {
      controller().saveCredentials(
        email: 'org@test.com',
        password: 'Secreta123',
      );
      controller().selectRole(UserRole.organizer);
      controller().savePersonalDetails(
        name: 'Org',
        lastname: 'Test',
        username: 'org.test',
        birthDate: '20/05/2000',
        cc: 'CC-123',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(registerControllerProvider);
      expect(state.status, RegisterStatus.success);
      expect(authRepo.registerCalled, isTrue);
      expect(organizerRepo.lastParams?.identificationDocument, 'CC-123');
    });
  });

  group('completeRegistration', () {
    test('usuario: Keycloak primero y sync con fecha ISO', () async {
      fillUserBasics();
      await controller().completeRegistration();

      final state = container.read(registerControllerProvider);
      expect(state.status, RegisterStatus.success);
      expect(authRepo.registerCalled, isTrue);
      expect(userRepo.lastParams?.birthDate, DateTime(2000, 5, 20));
      expect(userRepo.lastParams?.email, 'user@test.com');
    });

    test('si Keycloak falla no se intenta el sync', () async {
      authRepo.failRegister = true;
      fillUserBasics();
      await controller().completeRegistration();

      final state = container.read(registerControllerProvider);
      expect(state.status, RegisterStatus.error);
      expect(state.errorMessage, contains('Keycloak'));
      expect(userRepo.lastParams, isNull);
    });
  });
}
