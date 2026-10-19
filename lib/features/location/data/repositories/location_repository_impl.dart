import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/entities/location_consent.dart';
import '../../domain/entities/location_permission_status.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/device_location_data_source.dart';
import '../datasources/location_consent_local_data_source.dart';

/// Implementa el contrato del dominio. Traduce los tipos de geolocator a los
/// del dominio para que ninguna otra capa dependa del paquete, y
/// StorageException -> StorageFailure.
class LocationRepositoryImpl implements LocationRepository {
  final DeviceLocationDataSource deviceDataSource;
  final LocationConsentLocalDataSource consentDataSource;

  const LocationRepositoryImpl({
    required this.deviceDataSource,
    required this.consentDataSource,
  });

  @override
  Future<LocationConsent?> getConsent(String accountId) async {
    try {
      return await consentDataSource.read(accountId);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<void> saveConsent(String accountId, LocationConsent consent) async {
    try {
      await consentDataSource.write(accountId, consent);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      _toStatus(await deviceDataSource.checkPermission());

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      _toStatus(await deviceDataSource.requestPermission());

  @override
  Future<UserLocation?> getCurrentLocation({
    required Duration timeLimit,
  }) async => _toLocation(
    await deviceDataSource.getCurrentPosition(timeLimit: timeLimit),
    LocationSource.device,
  );

  @override
  Future<UserLocation?> getLastKnownLocation() async => _toLocation(
    await deviceDataSource.getLastKnownPosition(),
    LocationSource.lastKnown,
  );

  @override
  Future<bool> openAppSettings() => deviceDataSource.openAppSettings();

  static LocationPermissionStatus _toStatus(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationPermissionStatus.granted,
        LocationPermission.deniedForever =>
          LocationPermissionStatus.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
      };

  static UserLocation? _toLocation(Position? position, LocationSource source) {
    if (position == null) return null;
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: source,
    );
  }
}
