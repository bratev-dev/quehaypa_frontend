import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/entities/organizer.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/organizer_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_organizer_use_case.dart';
import 'package:frontend/features/authentication/domain/usecases/sync_profile_use_case.dart';
import 'package:frontend/features/preferences/domain/usecases/save_preferences_use_case.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_state.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';

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

  @override
  Future<User> updateProfile({
    required int id,
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) => throw UnimplementedError();
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

  @override
  Future<List<EventSeed>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required int radiusKm,
  }) => throw UnimplementedError();
}

AuthSession identity(String email) {
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'email': email,
        'preferred_username': 'identidad.keycloak',
        'given_name': 'Nombre de Keycloak',
        'family_name': 'Apellido de Keycloak',
      }),
    ),
  );
  return AuthSession(
    accessToken: 'header.$payload.signature',
    email: email,
    username: 'identidad.keycloak',
    firstName: 'Nombre de Keycloak',
    lastName: 'Apellido de Keycloak',
  );
}

void main() {
  late FakeUserRepository userRepo;
  late FakeOrganizerRepository organizerRepo;
  late FakePreferencesRepository preferencesRepo;
  late ProviderContainer container;

  setUp(() {
    userRepo = FakeUserRepository();
    organizerRepo = FakeOrganizerRepository();
    preferencesRepo = FakePreferencesRepository();
    container = ProviderContainer(
      overrides: [
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
    controller().startRegistration(identity('user@test.com'));
    controller().selectRole(UserRole.user);
    controller().savePersonalDetails(
      name: 'User',
      lastname: 'Test',
      username: 'user.test',
      birthDate: '20/05/2000',
    );
  }

  group('ramificación por rol', () {
    test(
      'iniciar el registro toma la identidad y descarta datos anteriores',
      () {
        fillUserBasics();
        controller().toggleInterest('Cine');
        controller().startRegistration(identity('nuevo@test.com'));
        final state = container.read(registerControllerProvider);
        expect(state.email, 'nuevo@test.com');
        expect(state.username, 'identidad.keycloak');
        expect(state.name, 'Nombre de Keycloak');
        expect(state.lastname, 'Apellido de Keycloak');
        expect(state.currentStep, RegisterStep.roleSelection);
        expect(state.selectedRole, isNull);
        expect(state.selectedInterests, isEmpty);
      },
    );
    test('usuario avanza a intereses sin disparar registro', () {
      fillUserBasics();

      final state = container.read(registerControllerProvider);
      expect(state.currentStep, RegisterStep.interests);
      expect(state.status, RegisterStatus.initial);
    });

    test('organizador dispara el registro automático', () async {
      controller().startRegistration(identity('org@test.com'));
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
      expect(organizerRepo.lastParams?.identificationDocument, 'CC-123');
    });
  });

  group('completeRegistration', () {
    test(
      'reintentar el cierre no vuelve a sincronizar un perfil guardado',
      () async {
        fillUserBasics();
        await controller().completeRegistration();
        controller().reportCompletionError();
        userRepo.failSync = true;
        await controller().completeRegistration();
        expect(
          container.read(registerControllerProvider).status,
          RegisterStatus.success,
        );
      },
    );
    test('usuario: sincroniza la identidad ya creada con fecha ISO', () async {
      fillUserBasics();
      await controller().completeRegistration();

      final state = container.read(registerControllerProvider);
      expect(state.status, RegisterStatus.success);
      expect(userRepo.lastParams?.birthDate, DateTime(2000, 5, 20));
      expect(userRepo.lastParams?.email, 'user@test.com');
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
