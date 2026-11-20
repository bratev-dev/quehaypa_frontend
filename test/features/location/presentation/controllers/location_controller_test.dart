import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';
import 'package:frontend/features/location/domain/entities/location_permission_status.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/domain/repositories/location_repository.dart';
import 'package:frontend/features/location/presentation/controllers/location_controller.dart';
import 'package:frontend/features/location/presentation/controllers/location_providers.dart';
import 'package:frontend/features/location/presentation/controllers/location_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationRepository extends Mock implements LocationRepository {}

class _FakeAuthenticationController extends AuthenticationController {
  _FakeAuthenticationController(this._initial);

  final AuthenticationState _initial;

  @override
  AuthenticationState build() => _initial;

  void signInAs(AuthenticationState next) => state = next;
}

AuthenticationState _signedIn(String sub, {bool isOrganizer = false}) {
  final claims = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  return AuthenticationState(
    status: AuthenticationStatus.authenticated,
    session: AuthSession(accessToken: 'header.$claims.signature', subject: sub),
    isOrganizer: isOrganizer,
  );
}

const _device = UserLocation(
  latitude: 2.45,
  longitude: -76.61,
  source: LocationSource.device,
);
const _lastKnown = UserLocation(
  latitude: 2.44,
  longitude: -76.60,
  source: LocationSource.lastKnown,
);

void main() {
  late _MockLocationRepository repository;
  late _FakeAuthenticationController authentication;
  late ProviderContainer container;
  late Map<String, LocationConsent> consents;

  LocationController controller() =>
      container.read(locationControllerProvider.notifier);
  LocationState state() => container.read(locationControllerProvider);

  void signIn(AuthenticationState auth) {
    authentication = _FakeAuthenticationController(auth);
    container = ProviderContainer(
      overrides: [
        authenticationControllerProvider.overrideWith(() => authentication),
        locationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  }

  setUpAll(() {
    registerFallbackValue(LocationConsent.granted);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    repository = _MockLocationRepository();
    consents = {};
    when(() => repository.getConsent(any()))
        .thenAnswer((i) async => consents[i.positionalArguments.first]);
    when(() => repository.saveConsent(any(), any())).thenAnswer((i) async {
      consents[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as LocationConsent;
    });
    when(() => repository.checkPermission())
        .thenAnswer((_) async => LocationPermissionStatus.granted);
    when(() => repository.requestPermission())
        .thenAnswer((_) async => LocationPermissionStatus.granted);
    when(
      () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
    ).thenAnswer((_) async => _device);
    when(() => repository.getLastKnownLocation())
        .thenAnswer((_) async => _lastKnown);
    when(() => repository.openAppSettings()).thenAnswer((_) async => true);
    signIn(_signedIn('sub-1'));
  });

  test('estado inicial: Popayán, sin aviso', () {
    expect(state().status, LocationStatus.idle);
    expect(state().location.isDefaultCity, isTrue);
    expect(state().notice, isNull);
  });

  group('onFeedOpened no hace nada', () {
    test('para un organizador', () async {
      signIn(_signedIn('org-1', isOrganizer: true));

      await controller().onFeedOpened();

      expect(state().status, LocationStatus.idle);
      verifyNever(() => repository.getConsent(any()));
    });

    test('sin sesión', () async {
      signIn(const AuthenticationState.initial());

      await controller().onFeedOpened();

      expect(state().status, LocationStatus.idle);
      verifyNever(() => repository.getConsent(any()));
    });
  });

  group('cuenta a la que nunca se le preguntó', () {
    test(
      'muestra el aviso una sola vez aunque el feed se abra de nuevo',
      () async {
        await controller().onFeedOpened();
        await controller().onFeedOpened();

        expect(state().status, LocationStatus.askingConsent);
        expect(state().accountId, 'sub-1');
        verify(() => repository.getConsent('sub-1')).called(1);
        verifyNever(() => repository.checkPermission());
      },
    );

    test('"Permitir" con permiso del sistema usa la posición actual', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      when(() => repository.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);
      await controller().onFeedOpened();
      // Tras pedirlo, el sistema ya lo reporta concedido.
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);

      await controller().allow();

      expect(consents['sub-1'], LocationConsent.granted);
      expect(state().status, LocationStatus.ready);
      expect(state().location, same(_device));
      expect(state().notice, isNull);
    });

    test('"Permitir" y el sistema lo niega: Popayán con aviso', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      when(() => repository.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      await controller().onFeedOpened();

      await controller().allow();

      expect(state().location.isDefaultCity, isTrue);
      expect(state().notice, LocationNotice.usingDefaultCity);
    });

    test('"Permitir" y falla algo inesperado: Popayán con aviso', () async {
      await controller().onFeedOpened();
      when(() => repository.saveConsent(any(), any()))
          .thenThrow(const StorageFailure('sin almacenamiento'));

      await controller().allow();

      expect(state().status, LocationStatus.ready);
      expect(state().location.isDefaultCity, isTrue);
      expect(state().notice, LocationNotice.usingDefaultCity);
    });

    test('"Ahora no" lo recuerda y usa Popayán con aviso', () async {
      await controller().onFeedOpened();

      await controller().decline();

      expect(consents['sub-1'], LocationConsent.declined);
      expect(state().location.isDefaultCity, isTrue);
      expect(state().notice, LocationNotice.usingDefaultCity);
      verifyNever(() => repository.requestPermission());
    });

    test('"Ahora no" sin poder guardarlo igual usa Popayán', () async {
      await controller().onFeedOpened();
      when(() => repository.saveConsent(any(), any()))
          .thenThrow(const StorageFailure('sin almacenamiento'));

      await controller().decline();

      expect(state().status, LocationStatus.ready);
      expect(state().notice, LocationNotice.usingDefaultCity);
    });

    test('Atrás no guarda nada y no vuelve a preguntar en la sesión', () async {
      await controller().onFeedOpened();

      controller().dismiss();
      expect(state().status, LocationStatus.ready);
      expect(state().notice, isNull);

      await controller().onFeedOpened();

      expect(state().status, LocationStatus.ready);
      expect(state().location.isDefaultCity, isTrue);
      expect(consents, isEmpty);
      verifyNever(() => repository.checkPermission());
    });
  });

  test(
    'las respuestas del aviso no hacen nada si no se está preguntando',
    () async {
      await controller().allow();
      await controller().decline();
      controller().dismiss();

      expect(state().status, LocationStatus.idle);
      verifyNever(() => repository.saveConsent(any(), any()));
    },
  );

  group('cuenta que ya respondió', () {
    test('rechazó: Popayán sin aviso ni consultar el sistema', () async {
      consents['sub-1'] = LocationConsent.declined;

      await controller().onFeedOpened();

      expect(state().status, LocationStatus.ready);
      expect(state().location.isDefaultCity, isTrue);
      expect(state().notice, isNull);
      verifyNever(() => repository.checkPermission());
    });

    test('aceptó: posición actual sin volver a pedir el permiso', () async {
      consents['sub-1'] = LocationConsent.granted;

      await controller().onFeedOpened();

      expect(state().location, same(_device));
      expect(state().notice, isNull);
      verifyNever(() => repository.requestPermission());
    });

    test(
      'aceptó pero luego lo quitó en el sistema: Popayán sin aviso',
      () async {
        consents['sub-1'] = LocationConsent.granted;
        when(() => repository.checkPermission())
            .thenAnswer((_) async => LocationPermissionStatus.deniedForever);

        await controller().onFeedOpened();

        expect(state().location.isDefaultCity, isTrue);
        expect(state().notice, isNull);
        verifyNever(() => repository.requestPermission());
      },
    );

    test('GPS sin respuesta: última conocida con aviso', () async {
      consents['sub-1'] = LocationConsent.granted;
      when(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).thenAnswer((_) async => null);

      await controller().onFeedOpened();

      expect(state().location, same(_lastKnown));
      expect(state().notice, LocationNotice.usingLastKnown);
    });

    test('GPS sin respuesta ni última conocida: Popayán con aviso', () async {
      consents['sub-1'] = LocationConsent.granted;
      when(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).thenAnswer((_) async => null);
      when(() => repository.getLastKnownLocation())
          .thenAnswer((_) async => null);

      await controller().onFeedOpened();

      expect(state().location.isDefaultCity, isTrue);
      expect(state().notice, LocationNotice.unavailable);
    });

    test('se vuelve a buscar cada vez que se abre el feed', () async {
      consents['sub-1'] = LocationConsent.granted;

      await controller().onFeedOpened();
      await controller().onFeedOpened();

      verify(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).called(2);
    });
  });

  test('si no se puede leer la respuesta usa Popayán sin romper', () async {
    when(() => repository.getConsent(any()))
        .thenThrow(const StorageFailure('sin almacenamiento'));

    await controller().onFeedOpened();

    expect(state().status, LocationStatus.ready);
    expect(state().location.isDefaultCity, isTrue);
    expect(state().notice, isNull);
  });

  test('otra cuenta en el mismo teléfono recibe su propio aviso', () async {
    consents['sub-1'] = LocationConsent.granted;
    await controller().onFeedOpened();
    expect(state().location, same(_device));

    authentication.signInAs(_signedIn('sub-2'));
    await controller().onFeedOpened();

    expect(state().status, LocationStatus.askingConsent);
    expect(state().accountId, 'sub-2');
    expect(state().location.isDefaultCity, isTrue);
  });

  group('enableFromSettings', () {
    test('no aplica a organizadores', () async {
      signIn(_signedIn('org-1', isOrganizer: true));

      expect(await controller().enableFromSettings(), isNull);
      verifyNever(() => repository.saveConsent(any(), any()));
    });

    test('tras "Ahora no", lo reactiva y usa la posición actual', () async {
      consents['sub-1'] = LocationConsent.declined;
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);

      final permission = await controller().enableFromSettings();

      expect(permission, LocationPermissionStatus.granted);
      expect(consents['sub-1'], LocationConsent.granted);
      expect(state().accountId, 'sub-1');
      expect(state().location, same(_device));
    });

    test('si el sistema lo bloqueó abre sus ajustes', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.deniedForever);

      final permission = await controller().enableFromSettings();

      expect(permission, LocationPermissionStatus.deniedForever);
      verify(() => repository.openAppSettings()).called(1);
      expect(state().location.isDefaultCity, isTrue);
    });

    test('un fallo devuelve null sin romper', () async {
      when(() => repository.saveConsent(any(), any()))
          .thenThrow(const StorageFailure('sin almacenamiento'));

      expect(await controller().enableFromSettings(), isNull);
    });
  });
}
