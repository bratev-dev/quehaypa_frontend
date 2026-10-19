import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Habla con el GPS a través de geolocator. Que el GPS esté apagado, no
/// responda a tiempo o el permiso se retire mientras se busca no son errores
/// del programa: se devuelve null y el dominio decide qué ubicación usar.
class DeviceLocationDataSource {
  final GeolocatorPlatform geolocator;

  const DeviceLocationDataSource({required this.geolocator});

  Future<LocationPermission> checkPermission() => geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      geolocator.requestPermission();

  Future<Position?> getCurrentPosition({required Duration timeLimit}) async {
    try {
      return await geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      return null;
    } on LocationServiceDisabledException {
      return null;
    } on PermissionDeniedException {
      return null;
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      return await geolocator.getLastKnownPosition();
    } on PermissionDeniedException {
      return null;
    }
  }

  Future<bool> openAppSettings() => geolocator.openAppSettings();
}
