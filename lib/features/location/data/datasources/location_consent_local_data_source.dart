import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/location_consent.dart';

/// Guarda la respuesta al aviso de ubicación por cuenta (`sub` del token).
/// Usa claves propias, así que cerrar sesión no la borra; desinstalar sí,
/// porque el sistema elimina la llave con la que se cifró.
class LocationConsentLocalDataSource {
  static const _keyPrefix = 'location_consent_';

  final FlutterSecureStorage storage;

  const LocationConsentLocalDataSource({required this.storage});

  Future<LocationConsent?> read(String accountId) async {
    try {
      final value = await storage.read(key: '$_keyPrefix$accountId');
      return LocationConsent.values.asNameMap()[value];
    } on PlatformException {
      throw const StorageException(
        'No fue posible leer tu preferencia de ubicación.',
      );
    }
  }

  Future<void> write(String accountId, LocationConsent consent) async {
    try {
      await storage.write(key: '$_keyPrefix$accountId', value: consent.name);
    } on PlatformException {
      throw const StorageException(
        'No fue posible guardar tu preferencia de ubicación.',
      );
    }
  }
}
