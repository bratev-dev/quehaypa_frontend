import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';
import 'package:frontend/features/location/domain/entities/location_permission_status.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/domain/repositories/location_repository.dart';
import 'package:frontend/features/location/domain/usecases/location_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockLocationRepository repository;

  const device = UserLocation(
    latitude: 2.45,
    longitude: -76.61,
    source: LocationSource.device,
  );
  const lastKnown = UserLocation(
    latitude: 2.44,
    longitude: -76.60,
    source: LocationSource.lastKnown,
  );

  setUpAll(() {
    registerFallbackValue(LocationConsent.granted);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    repository = MockLocationRepository();
    when(() => repository.saveConsent(any(), any())).thenAnswer((_) async {});
    when(() => repository.openAppSettings()).thenAnswer((_) async => true);
  });

  test('Popayán es el Parque Caldas y se reconoce como ciudad por defecto', () {
    expect(UserLocation.defaultCity.latitude, 2.4419);
    expect(UserLocation.defaultCity.longitude, -76.6063);
    expect(UserLocation.defaultCity.isDefaultCity, isTrue);
    expect(device.isDefaultCity, isFalse);
  });

  group('GetLocationConsent', () {
    test('devuelve la respuesta guardada de la cuenta', () async {
      when(() => repository.getConsent('sub-1'))
          .thenAnswer((_) async => LocationConsent.declined);

      expect(
        await GetLocationConsent(repository)('sub-1'),
        LocationConsent.declined,
      );
    });

    test('devuelve null si a la cuenta nunca se le preguntó', () async {
      when(() => repository.getConsent('sub-2')).thenAnswer((_) async => null);

      expect(await GetLocationConsent(repository)('sub-2'), isNull);
    });
  });

  test('DeclineLocationAccess guarda "rechazado" para la cuenta', () async {
    await DeclineLocationAccess(repository)('sub-1');

    verify(() => repository.saveConsent('sub-1', LocationConsent.declined))
        .called(1);
  });

  group('RequestLocationAccess', () {
    test(
      'si el sistema ya concedió el permiso no muestra su diálogo',
      () async {
        when(() => repository.checkPermission())
            .thenAnswer((_) async => LocationPermissionStatus.granted);

        final status = await RequestLocationAccess(repository)('sub-1');

        expect(status, LocationPermissionStatus.granted);
        verify(() => repository.saveConsent('sub-1', LocationConsent.granted))
            .called(1);
        verifyNever(() => repository.requestPermission());
      },
    );

    test('si todavía se puede pedir, muestra el diálogo del sistema', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      when(() => repository.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);

      final status = await RequestLocationAccess(repository)('sub-1');

      expect(status, LocationPermissionStatus.granted);
      verify(() => repository.requestPermission()).called(1);
    });

    test('si el sistema lo bloqueó no abre los ajustes por defecto', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.deniedForever);

      final status = await RequestLocationAccess(repository)('sub-1');

      expect(status, LocationPermissionStatus.deniedForever);
      verifyNever(() => repository.requestPermission());
      verifyNever(() => repository.openAppSettings());
    });

    test(
      'desde Configuración abre los ajustes si el sistema lo bloqueó',
      () async {
        when(() => repository.checkPermission())
            .thenAnswer((_) async => LocationPermissionStatus.deniedForever);

        await RequestLocationAccess(repository)(
          'sub-1',
          openSettingsIfBlocked: true,
        );

        verify(() => repository.openAppSettings()).called(1);
      },
    );

    test('rechazar el diálogo del sistema deja el estado denegado', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);
      when(() => repository.requestPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);

      final status = await RequestLocationAccess(repository)(
        'sub-1',
        openSettingsIfBlocked: true,
      );

      expect(status, LocationPermissionStatus.denied);
      verifyNever(() => repository.openAppSettings());
    });
  });

  group('ResolveUserLocation', () {
    test('sin permiso del sistema usa Popayán sin consultar el GPS', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.denied);

      final result = await ResolveUserLocation(repository)();

      expect(result.location.isDefaultCity, isTrue);
      expect(result.deviceUnavailable, isFalse);
      verifyNever(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      );
      verifyNever(() => repository.requestPermission());
    });

    test('con permiso usa la posición actual con límite de 10 s', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);
      when(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).thenAnswer((_) async => device);

      final result = await ResolveUserLocation(repository)();

      expect(result.location, same(device));
      expect(result.deviceUnavailable, isFalse);
      verify(
        () => repository.getCurrentLocation(
          timeLimit: const Duration(seconds: 10),
        ),
      ).called(1);
    });

    test('si el GPS no responde usa la última conocida y avisa', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);
      when(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).thenAnswer((_) async => null);
      when(() => repository.getLastKnownLocation())
          .thenAnswer((_) async => lastKnown);

      final result = await ResolveUserLocation(repository)();

      expect(result.location, same(lastKnown));
      expect(result.deviceUnavailable, isTrue);
    });

    test('sin GPS ni última conocida usa Popayán y avisa', () async {
      when(() => repository.checkPermission())
          .thenAnswer((_) async => LocationPermissionStatus.granted);
      when(
        () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
      ).thenAnswer((_) async => null);
      when(() => repository.getLastKnownLocation())
          .thenAnswer((_) async => null);

      final result = await ResolveUserLocation(repository)();

      expect(result.location.isDefaultCity, isTrue);
      expect(result.deviceUnavailable, isTrue);
    });
  });
}
