import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/device_location_data_source.dart';
import '../../data/datasources/location_consent_local_data_source.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location_use_cases.dart';

final deviceLocationDataSourceProvider = Provider<DeviceLocationDataSource>((
  ref,
) {
  return DeviceLocationDataSource(geolocator: GeolocatorPlatform.instance);
});

final locationConsentLocalDataSourceProvider =
    Provider<LocationConsentLocalDataSource>((ref) {
      return const LocationConsentLocalDataSource(
        storage: FlutterSecureStorage(),
      );
    });

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    deviceDataSource: ref.read(deviceLocationDataSourceProvider),
    consentDataSource: ref.read(locationConsentLocalDataSourceProvider),
  );
});

final getLocationConsentUseCaseProvider = Provider<GetLocationConsent>((ref) {
  return GetLocationConsent(ref.read(locationRepositoryProvider));
});

final declineLocationAccessUseCaseProvider = Provider<DeclineLocationAccess>((
  ref,
) {
  return DeclineLocationAccess(ref.read(locationRepositoryProvider));
});

final requestLocationAccessUseCaseProvider = Provider<RequestLocationAccess>((
  ref,
) {
  return RequestLocationAccess(ref.read(locationRepositoryProvider));
});

final resolveUserLocationUseCaseProvider = Provider<ResolveUserLocation>((ref) {
  return ResolveUserLocation(ref.read(locationRepositoryProvider));
});
