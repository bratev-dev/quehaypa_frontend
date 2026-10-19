import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/location_consent.dart';

/// Guarda la respuesta al aviso de ubicación por cuenta (`sub` del token).
/// Usa claves propias, así que cerrar sesión no la borra; desinstalar sí,
/// porque el sistema elimina la llave con la que se cifró.
class LocationConsentLocalDataSource {
  static const _keyPrefix = 'location_consent_';

  final FlutterSecureStorage storage;

  const LocationConsentLocalDataSource({required this.storage});

  Future<LocationConsent?> read(String accountId) async {
    final value = await storage.read(key: '$_keyPrefix$accountId');
    return LocationConsent.values.asNameMap()[value];
  }

  Future<void> write(String accountId, LocationConsent consent) =>
      storage.write(key: '$_keyPrefix$accountId', value: consent.name);
}
