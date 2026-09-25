import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/entities/organizer.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/organizer_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/register_with_keycloak_use_case.dart';
import 'package:frontend/features/preferences/domain/usecases/save_preferences_use_case.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';

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
  bool failSync = false;

  @override
  Future<User> syncProfile(SyncProfileParams params) async {
    if (failSync) {
      throw const ServerFailure('Error interno del servidor');
    }
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

class FakePreferencesRepository implements PreferencesRepository {
  bool failSave = false;

  @override
  Future<List<String>> saveMyPreferences(List<String> categories) async {
    if (failSave) {
      throw const ServerFailure('Error interno del servidor');
    }
    return categories;
  }

  @override
  Future<List<String>> getMyPreferences() => throw UnimplementedError();

  @override
  Future<List<Interest>> getInterests() => throw UnimplementedError();

  @override
  Future<List<EventSeed>> getFeed() => throw UnimplementedError();

  @override
  Future<List<EventSeed>> getEvents({String? category}) =>
      throw UnimplementedError();
}

void main() {
  late FakeAuthRepository authRepo;
  late FakeUserRepository userRepo;
  late FakeOrganizerRepository organizerRepo;
  late FakePreferencesRepository preferencesRepo;
  late ProviderContainer container;

  setUp(() {
    authRepo = FakeAuthRepository();
    userRepo = FakeUserRepository();
    organizerRepo = FakeOrganizerRepository();
    preferencesRepo = FakePreferencesRepository();
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
        saveMyPreferencesUseCaseProvider.overrideWithValue(
          SaveMyPreferences(preferencesRepo),
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

    test('si el sync falla indica el paso de perfil', () async {
      userRepo.failSync = true;
      fillUserBasics();
      await controller().completeRegistration();

      final state = container.read(registerControllerProvider);
      expect(state.status, RegisterStatus.error);
      expect(state.errorMessage, contains('perfil'));
    });

    test(
      'si intereses falla indica el paso aunque el perfil quedo creado',
      () async {
        preferencesRepo.failSave = true;
        fillUserBasics();
        controller().toggleInterest('Musica');
        controller().toggleInterest('Cine');
        controller().toggleInterest('Arte');
        controller().toggleInterest('Lectura');
        await controller().completeRegistration();

        final state = container.read(registerControllerProvider);
        expect(state.status, RegisterStatus.error);
        expect(state.errorMessage, contains('intereses'));
        // El perfil sí quedó creado (estricto solo bloquea el éxito).
        expect(userRepo.lastParams, isNotNull);
      },
    );
  });
}
