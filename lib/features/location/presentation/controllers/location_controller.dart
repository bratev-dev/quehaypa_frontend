import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../domain/entities/location_permission_status.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/location_use_cases.dart';
import 'location_providers.dart';
import 'location_state.dart';

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

/// Coordina el aviso de ubicación del feed (HU-5.1), solo para usuarios
/// regulares. Nunca lanza hacia la UI: ante cualquier fallo usa Popayán.
class LocationController extends Notifier<LocationState> {
  /// Cuentas que cerraron el aviso sin elegir: no se les vuelve a preguntar
  /// hasta que la app se abra de nuevo.
  final _dismissed = <String>{};

  @override
  LocationState build() => const LocationState();

  /// Al abrir el feed: pregunta si la cuenta nunca respondió; si ya respondió,
  /// busca la ubicación sin volver a pedir el permiso del sistema.
  Future<void> onFeedOpened() async {
    final accountId = _currentAccountId();
    if (accountId == null || _isBusy(accountId)) return;
    state = accountId == state.accountId
        ? state.copyWith(status: LocationStatus.checking)
        : LocationState(status: LocationStatus.checking, accountId: accountId);
    try {
      final consent = await ref.read(getLocationConsentUseCaseProvider)(
        accountId,
      );
      if (consent == null && !_dismissed.contains(accountId)) {
        state = state.copyWith(status: LocationStatus.askingConsent);
        return;
      }
      await _resolve(accountId);
    } catch (_) {
      _useDefaultCity();
    }
  }

  /// "Permitir": pide el permiso del sistema y busca la ubicación.
  Future<void> allow() async {
    final accountId = _askedAccountId();
    if (accountId == null) return;
    state = state.copyWith(status: LocationStatus.resolving);
    try {
      final permission = await ref.read(requestLocationAccessUseCaseProvider)(
        accountId,
      );
      await _resolve(
        accountId,
        systemDenied: permission != LocationPermissionStatus.granted,
      );
    } catch (_) {
      _useDefaultCity(notice: LocationNotice.usingDefaultCity);
    }
  }

  /// "Ahora no": se recuerda y se usa Popayán (CA2).
  Future<void> decline() async {
    final accountId = _askedAccountId();
    if (accountId == null) return;
    try {
      await ref.read(declineLocationAccessUseCaseProvider)(accountId);
    } catch (_) {
      // Si no se pudo guardar, se le volverá a preguntar la próxima vez.
    }
    _useDefaultCity(notice: LocationNotice.usingDefaultCity);
  }

  /// Cerró el aviso con Atrás: no cuenta como respuesta.
  void dismiss() {
    final accountId = _askedAccountId();
    if (accountId == null) return;
    _dismissed.add(accountId);
    _useDefaultCity();
  }

  /// Opción "Ubicación" de Configuración (CA5): vuelve a pedir el permiso o,
  /// si el sistema lo bloqueó, abre sus ajustes. Null si no aplica o falla.
  Future<LocationPermissionStatus?> enableFromSettings() async {
    final accountId = _currentAccountId();
    if (accountId == null) return null;
    try {
      final permission = await ref.read(requestLocationAccessUseCaseProvider)(
        accountId,
        openSettingsIfBlocked: true,
      );
      if (accountId != state.accountId) {
        state = LocationState(accountId: accountId);
      }
      if (permission == LocationPermissionStatus.granted) {
        await _resolve(accountId);
      }
      return permission;
    } catch (_) {
      return null;
    }
  }

  Future<void> _resolve(String accountId, {bool systemDenied = false}) async {
    state = state.copyWith(status: LocationStatus.resolving);
    final result = await ref.read(resolveUserLocationUseCaseProvider)(
      accountId,
    );
    // La sesión pudo cambiar mientras se buscaba.
    if (state.accountId != accountId) return;
    state = state.copyWith(
      status: LocationStatus.ready,
      location: result.location,
      notice: _noticeFor(result, systemDenied: systemDenied),
    );
  }

  void _useDefaultCity({LocationNotice? notice}) {
    state = state.copyWith(
      status: LocationStatus.ready,
      location: UserLocation.defaultCity,
      notice: notice,
    );
  }

  static LocationNotice? _noticeFor(
    LocationResolution result, {
    required bool systemDenied,
  }) {
    if (result.deviceUnavailable) {
      return result.location.isDefaultCity
          ? LocationNotice.unavailable
          : LocationNotice.usingLastKnown;
    }
    return systemDenied ? LocationNotice.usingDefaultCity : null;
  }

  bool _isBusy(String accountId) =>
      accountId == state.accountId &&
      (state.status == LocationStatus.checking ||
          state.status == LocationStatus.askingConsent ||
          state.status == LocationStatus.resolving);

  String? _askedAccountId() =>
      state.status == LocationStatus.askingConsent ? state.accountId : null;

  /// Solo usuarios regulares con sesión: el organizador no ve el feed.
  String? _currentAccountId() {
    final authentication = ref.read(authenticationControllerProvider);
    final subject = authentication.session?.subject ?? '';
    if (authentication.isOrganizer || subject.isEmpty) return null;
    return subject;
  }
}
