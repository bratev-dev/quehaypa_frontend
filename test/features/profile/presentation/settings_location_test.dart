import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';
import 'package:frontend/features/location/domain/entities/location_permission_status.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/domain/repositories/location_repository.dart';
import 'package:frontend/features/location/presentation/controllers/location_providers.dart';
import 'package:frontend/features/profile/presentation/pages/settings_page.dart';
import 'package:frontend/features/profile/presentation/profile_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationRepository extends Mock implements LocationRepository {}

class _FakeAuthenticationController extends AuthenticationController {
  _FakeAuthenticationController(this._initial);

  final AuthenticationState _initial;

  @override
  AuthenticationState build() => _initial;
}

AuthenticationState _signedIn({bool isOrganizer = false}) {
  final claims = base64Url.encode(utf8.encode(jsonEncode({'sub': 'sub-1'})));
  return AuthenticationState(
    status: AuthenticationStatus.authenticated,
    session: AuthSession(accessToken: 'header.$claims.signature'),
    isOrganizer: isOrganizer,
  );
}

const _user = User(
  id: 1,
  username: 'juan',
  firstName: 'Juan',
  lastName: 'Chávez',
  email: 'juan@example.com',
  isActive: true,
);

void main() {
  late _MockLocationRepository repository;

  setUpAll(() {
    registerFallbackValue(LocationConsent.granted);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    repository = _MockLocationRepository();
    when(() => repository.saveConsent(any(), any())).thenAnswer((_) async {});
    when(() => repository.getConsent(any()))
        .thenAnswer((_) async => LocationConsent.granted);
    when(() => repository.checkPermission())
        .thenAnswer((_) async => LocationPermissionStatus.granted);
    when(
      () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
    ).thenAnswer(
      (_) async => const UserLocation(
        latitude: 2.45,
        longitude: -76.61,
        source: LocationSource.device,
      ),
    );
    when(() => repository.openAppSettings()).thenAnswer((_) async => true);
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    bool isOrganizer = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileProvider.overrideWith((ref) async => _user),
          authenticationControllerProvider.overrideWith(
            () => _FakeAuthenticationController(
              _signedIn(isOrganizer: isOrganizer),
            ),
          ),
          locationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLocation(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Ubicación'));
    await tester.tap(find.text('Ubicación'));
    await tester.pumpAndSettle();
  }

  /// Deja vencer el aviso superior (dura 3 s) para no dejar timers vivos.
  Future<void> letNoticeExpire(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('el organizador no ve la opción de ubicación', (tester) async {
    await pumpSettings(tester, isOrganizer: true);

    expect(find.text('Mis intereses'), findsOneWidget);
    expect(find.text('Ubicación'), findsNothing);
  });

  testWidgets('con permiso concedido la activa', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Planes y eventos cerca de ti'), findsOneWidget);

    await tapLocation(tester);

    verify(() => repository.saveConsent('sub-1', LocationConsent.granted))
        .called(1);
    expect(find.text('Ubicación activada.'), findsOneWidget);
    await letNoticeExpire(tester);
  });

  testWidgets('si el sistema la bloqueó abre sus ajustes', (tester) async {
    when(() => repository.checkPermission())
        .thenAnswer((_) async => LocationPermissionStatus.deniedForever);
    await pumpSettings(tester);

    await tapLocation(tester);

    verify(() => repository.openAppSettings()).called(1);
    expect(
      find.text(
        'Activa la ubicación en los ajustes del teléfono y vuelve a la app.',
      ),
      findsOneWidget,
    );
    await letNoticeExpire(tester);
  });

  testWidgets('si rechaza el diálogo del sistema usa Popayán', (tester) async {
    when(() => repository.checkPermission())
        .thenAnswer((_) async => LocationPermissionStatus.denied);
    when(() => repository.requestPermission())
        .thenAnswer((_) async => LocationPermissionStatus.denied);
    await pumpSettings(tester);

    await tapLocation(tester);

    expect(
      find.text('No se activó la ubicación. Usaremos Popayán como referencia.'),
      findsOneWidget,
    );
    await letNoticeExpire(tester);
  });

  testWidgets('un fallo muestra que se puede reintentar', (tester) async {
    when(() => repository.saveConsent(any(), any()))
        .thenThrow(const StorageFailure('sin almacenamiento'));
    await pumpSettings(tester);

    await tapLocation(tester);

    expect(
      find.text('No pudimos activar la ubicación. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    await letNoticeExpire(tester);
  });
}
