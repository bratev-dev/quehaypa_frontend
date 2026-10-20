import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/location/data/datasources/device_location_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform geolocator;
  late DeviceLocationDataSource dataSource;

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

  setUpAll(() => registerFallbackValue(const LocationSettings()));

  setUp(() {
    geolocator = MockGeolocatorPlatform();
    dataSource = DeviceLocationDataSource(geolocator: geolocator);
    when(() => geolocator.isLocationServiceEnabled())
        .thenAnswer((_) async => true);
  });

  void stubCurrentPosition(Future<Position> Function() answer) {
    when(
      () => geolocator.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('getCurrentPosition', () {
    test('pide precisión alta con el límite de tiempo recibido', () async {
      stubCurrentPosition(() async => position);

      final result = await dataSource.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      expect(result, same(position));
      final settings =
          verify(
                () => geolocator.getCurrentPosition(
                  locationSettings: captureAny(named: 'locationSettings'),
                ),
              ).captured.single
              as LocationSettings;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.timeLimit, const Duration(seconds: 10));
    });

    test('devuelve null si el GPS no responde a tiempo', () async {
      stubCurrentPosition(() async => throw TimeoutException('sin señal'));

      expect(
        await dataSource.getCurrentPosition(timeLimit: Duration.zero),
        isNull,
      );
    });

    test(
      'con el GPS apagado no busca ni muestra el diálogo de Google',
      () async {
        when(() => geolocator.isLocationServiceEnabled())
            .thenAnswer((_) async => false);

        expect(
          await dataSource.getCurrentPosition(timeLimit: Duration.zero),
          isNull,
        );
        verifyNever(
          () => geolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        );
      },
    );

    test('devuelve null si el GPS se apaga mientras busca', () async {
      stubCurrentPosition(
        () async => throw const LocationServiceDisabledException(),
      );

      expect(
        await dataSource.getCurrentPosition(timeLimit: Duration.zero),
        isNull,
      );
    });

    test('devuelve null si el permiso se retiró mientras buscaba', () async {
      stubCurrentPosition(
        () async => throw const PermissionDeniedException('retirado'),
      );

      expect(
        await dataSource.getCurrentPosition(timeLimit: Duration.zero),
        isNull,
      );
    });
  });

  group('getLastKnownPosition', () {
    test('devuelve la última posición del sistema', () async {
      when(() => geolocator.getLastKnownPosition())
          .thenAnswer((_) async => position);

      expect(await dataSource.getLastKnownPosition(), same(position));
    });

    test('devuelve null si el permiso se retiró', () async {
      when(() => geolocator.getLastKnownPosition())
          .thenThrow(const PermissionDeniedException('retirado'));

      expect(await dataSource.getLastKnownPosition(), isNull);
    });
  });

  test(
    'consultar, pedir permiso y abrir ajustes delegan en geolocator',
    () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => geolocator.openAppSettings()).thenAnswer((_) async => true);

      expect(await dataSource.checkPermission(), LocationPermission.denied);
      expect(
        await dataSource.requestPermission(),
        LocationPermission.whileInUse,
      );
      expect(await dataSource.openAppSettings(), isTrue);
    },
  );
}
