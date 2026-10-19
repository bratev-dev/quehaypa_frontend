import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/location/data/datasources/location_consent_local_data_source.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';

void main() {
  const dataSource = LocationConsentLocalDataSource(
    storage: FlutterSecureStorage(),
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('devuelve null si a la cuenta nunca se le preguntó', () async {
    expect(await dataSource.read('sub-1'), isNull);
  });

  test('recuerda la respuesta de cada cuenta por separado', () async {
    await dataSource.write('sub-1', LocationConsent.declined);
    await dataSource.write('sub-2', LocationConsent.granted);

    expect(await dataSource.read('sub-1'), LocationConsent.declined);
    expect(await dataSource.read('sub-2'), LocationConsent.granted);
  });

  test('guarda con la clave location_consent_<sub>', () async {
    await dataSource.write('sub-1', LocationConsent.granted);

    expect(
      await const FlutterSecureStorage().read(key: 'location_consent_sub-1'),
      'granted',
    );
  });

  test('un valor desconocido cuenta como nunca preguntado', () async {
    FlutterSecureStorage.setMockInitialValues({
      'location_consent_sub-1': 'quizas',
    });

    expect(await dataSource.read('sub-1'), isNull);
  });
}
