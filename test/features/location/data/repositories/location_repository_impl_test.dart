import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/location/data/datasources/device_location_data_source.dart';
import 'package:frontend/features/location/data/datasources/location_consent_local_data_source.dart';
import 'package:frontend/features/location/data/repositories/location_repository_impl.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';
import 'package:frontend/features/location/domain/entities/location_permission_status.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceLocationDataSource extends Mock
    implements DeviceLocationDataSource {}

class MockLocationConsentLocalDataSource extends Mock
    implements LocationConsentLocalDataSource {}

void main() {
  late MockDeviceLocationDataSource device;
  late MockLocationConsentLocalDataSource consent;
  late LocationRepositoryImpl repository;

  final position = Position(
    latitude: 2.45,
    longitude: -76.61,
    timestamp: DateTime(2026, 10, 19),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  setUpAll(() {
    registerFallbackValue(LocationConsent.granted);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    device = MockDeviceLocationDataSource();
    consent = MockLocationConsentLocalDataSource();
    repository = LocationRepositoryImpl(
      deviceDataSource: device,
      consentDataSource: consent,
    );
  });

  group('traduce el permiso de geolocator al del dominio', () {
    const cases = {
      LocationPermission.whileInUse: LocationPermissionStatus.granted,
      LocationPermission.always: LocationPermissionStatus.granted,
      LocationPermission.denied: LocationPermissionStatus.denied,
      LocationPermission.unableToDetermine: LocationPermissionStatus.denied,
      LocationPermission.deniedForever: LocationPermissionStatus.deniedForever,
    };

    cases.forEach((permission, status) {
      test('${permission.name} -> ${status.name}', () async {
        when(() => device.checkPermission())
            .thenAnswer((_) async => permission);
        when(() => device.requestPermission())
            .thenAnswer((_) async => permission);

        expect(await repository.checkPermission(), status);
        expect(await repository.requestPermission(), status);
      });
    });
  });

  test('la posición actual se marca como del dispositivo', () async {
    when(
      () => device.getCurrentPosition(timeLimit: const Duration(seconds: 10)),
    ).thenAnswer((_) async => position);

    final location = await repository.getCurrentLocation(
      timeLimit: const Duration(seconds: 10),
    );

    expect(location!.latitude, 2.45);
    expect(location.longitude, -76.61);
    expect(location.source, LocationSource.device);
  });

  test('la última conocida se marca como tal', () async {
    when(() => device.getLastKnownPosition()).thenAnswer((_) async => position);

    final location = await repository.getLastKnownLocation();

    expect(location!.source, LocationSource.lastKnown);
  });

  test('sin posición devuelve null', () async {
    when(() => device.getCurrentPosition(timeLimit: any(named: 'timeLimit')))
        .thenAnswer((_) async => null);
    when(() => device.getLastKnownPosition()).thenAnswer((_) async => null);

    expect(
      await repository.getCurrentLocation(timeLimit: Duration.zero),
      isNull,
    );
    expect(await repository.getLastKnownLocation(), isNull);
  });

  test('el consentimiento y los ajustes delegan en sus fuentes', () async {
    when(() => consent.read('sub-1'))
        .thenAnswer((_) async => LocationConsent.declined);
    when(() => consent.write(any(), any())).thenAnswer((_) async {});
    when(() => device.openAppSettings()).thenAnswer((_) async => false);

    expect(await repository.getConsent('sub-1'), LocationConsent.declined);
    await repository.saveConsent('sub-1', LocationConsent.granted);
    verify(() => consent.write('sub-1', LocationConsent.granted)).called(1);
    expect(await repository.openAppSettings(), isFalse);
  });
}
