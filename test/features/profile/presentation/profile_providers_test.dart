import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/entities/organizer.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/domain/repositories/organizer_repository.dart';
import 'package:frontend/features/authentication/domain/repositories/user_repository.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/authentication/presentation/controllers/register_providers.dart';
import 'package:frontend/features/profile/presentation/profile_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Users extends Mock implements UserRepository {}

class _Organizers extends Mock implements OrganizerRepository {}

class _Auth extends AuthenticationController {
  _Auth(this.initial);
  final AuthenticationState initial;

  @override
  AuthenticationState build() => initial;

  void signIn(String subject, {bool isOrganizer = false}) {
    state = _signedIn(subject, isOrganizer: isOrganizer);
  }
}

AuthenticationState _signedIn(String subject, {bool isOrganizer = false}) =>
    AuthenticationState(
      status: AuthenticationStatus.authenticated,
      session: AuthSession(accessToken: 'test', subject: subject),
      isOrganizer: isOrganizer,
    );

const _regular = User(
  id: 1,
  username: 'regular',
  firstName: 'Usuario',
  lastName: 'Prueba',
  email: 'regular@example.com',
  birthDate: null,
  profilePictureUrl: 'https://example.com/avatar.png',
  isActive: true,
);

const _organizer = Organizer(
  id: 2,
  username: 'organizador',
  firstName: 'Organizador',
  lastName: 'Prueba',
  email: 'organizador@example.com',
  identificationDocument: '123',
  isActive: true,
);

void main() {
  test('carga cada rol y descarta el perfil al cambiar de cuenta', () async {
    final users = _Users();
    final organizers = _Organizers();
    when(users.getProfile).thenAnswer((_) async => _regular);
    when(organizers.getProfile).thenAnswer((_) async => _organizer);
    final auth = _Auth(_signedIn('regular'));
    final container = ProviderContainer(
      overrides: [
        authenticationControllerProvider.overrideWith(() => auth),
        userRepositoryProvider.overrideWithValue(users),
        organizerRepositoryProvider.overrideWithValue(organizers),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(myProfileProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(await container.read(myProfileProvider.future), same(_regular));
    verifyNever(organizers.getProfile);

    auth.signIn('organizer', isOrganizer: true);
    final profile = await container.read(myProfileProvider.future);
    expect(profile.id, _organizer.id);
    expect(profile.username, _organizer.username);
    expect(profile.firstName, _organizer.firstName);
    expect(profile.lastName, _organizer.lastName);
    expect(profile.email, _organizer.email);
    expect(profile.isActive, _organizer.isActive);
    expect(profile.profilePictureUrl, isNull);
    verify(organizers.getProfile).called(1);
    verify(users.getProfile).called(1);

    auth.signIn('another-organizer', isOrganizer: true);
    await container.read(myProfileProvider.future);
    verify(organizers.getProfile).called(1);

    auth.signIn('regular');
    expect(await container.read(myProfileProvider.future), same(_regular));
    verify(users.getProfile).called(1);
  });

  final baseUrl = Platform.environment['LIVE_API_BASE_URL'] ?? '';
  for (final role in ['ORGANIZER', 'REGULAR']) {
    final token = Platform.environment['${role}_TOKEN'] ?? '';
    test(
      'perfil $role real: provider, repositorio y datasource',
      () async {
        final dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'Authorization': 'Bearer $token'},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        addTearDown(() => dio.close(force: true));
        final container = ProviderContainer(
          overrides: [
            authenticationControllerProvider.overrideWith(
              () => _Auth(_signedIn(role, isOrganizer: role == 'ORGANIZER')),
            ),
            dioProvider.overrideWithValue(dio),
          ],
        );
        addTearDown(container.dispose);
        final profile = await container.read(myProfileProvider.future);
        expect(profile.id, greaterThan(0));
        expect(
          profile.email,
          role == 'ORGANIZER' ? 'prueba77@gmail.com' : 'prueba78@gmail.com',
        );
        expect(profile.username, isNotEmpty);
        expect(profile.firstName, isNotEmpty);
      },
      skip: baseUrl.isEmpty || token.isEmpty
          ? 'Requiere LIVE_API_BASE_URL y token privado del rol'
          : false,
    );
  }
}
