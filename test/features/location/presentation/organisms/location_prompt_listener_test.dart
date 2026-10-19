import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/location/domain/entities/location_consent.dart';
import 'package:frontend/features/location/domain/entities/location_permission_status.dart';
import 'package:frontend/features/location/domain/entities/user_location.dart';
import 'package:frontend/features/location/domain/repositories/location_repository.dart';
import 'package:frontend/features/location/presentation/controllers/location_providers.dart';
import 'package:frontend/features/location/presentation/controllers/location_state.dart';
import 'package:frontend/features/location/presentation/organisms/location_prompt_listener.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationRepository extends Mock implements LocationRepository {}

class _FakeAuthenticationController extends AuthenticationController {
  _FakeAuthenticationController(this._initial);

  final AuthenticationState _initial;

  @override
  AuthenticationState build() => _initial;
}

AuthenticationState _signedIn(String sub, {bool isOrganizer = false}) {
  final claims = base64Url.encode(utf8.encode(jsonEncode({'sub': sub})));
  return AuthenticationState(
    status: AuthenticationStatus.authenticated,
    session: AuthSession(accessToken: 'header.$claims.signature'),
    isOrganizer: isOrganizer,
  );
}

const _title = '¿Permitir el acceso a tu ubicación?';

void main() {
  late _MockLocationRepository repository;
  late Map<String, LocationConsent> consents;

  setUpAll(() {
    registerFallbackValue(LocationConsent.granted);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    repository = _MockLocationRepository();
    consents = {};
    when(() => repository.getConsent(any()))
        .thenAnswer((i) async => consents[i.positionalArguments.first]);
    when(() => repository.saveConsent(any(), any())).thenAnswer((i) async {
      consents[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as LocationConsent;
    });
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
  });

  Future<void> pumpFeed(
    WidgetTester tester, {
    AuthenticationState? authentication,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationControllerProvider.overrideWith(
            () => _FakeAuthenticationController(
              authentication ?? _signedIn('sub-1'),
            ),
          ),
          locationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LocationPromptListener(child: Text('Feed'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Deja vencer el aviso superior (dura 3 s) para no dejar timers vivos.
  Future<void> letNoticeExpire(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('la primera vez muestra el aviso sobre el feed', (tester) async {
    await pumpFeed(tester);

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
    expect(find.textContaining('usaremos Popayán'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
    expect(find.text('Permitir'), findsOneWidget);
  });

  testWidgets('"Ahora no" lo recuerda y avisa que usará Popayán', (
    tester,
  ) async {
    await pumpFeed(tester);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    expect(consents['sub-1'], LocationConsent.declined);
    expect(find.text(LocationNotice.usingDefaultCity.message), findsOneWidget);
    await letNoticeExpire(tester);
  });

  testWidgets('"Permitir" pide el permiso del sistema', (tester) async {
    when(() => repository.checkPermission())
        .thenAnswer((_) async => LocationPermissionStatus.denied);
    when(() => repository.requestPermission())
        .thenAnswer((_) async => LocationPermissionStatus.denied);
    await pumpFeed(tester);

    await tester.tap(find.text('Permitir'));
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    expect(consents['sub-1'], LocationConsent.granted);
    verify(() => repository.requestPermission()).called(1);
    expect(find.text(LocationNotice.usingDefaultCity.message), findsOneWidget);
    await letNoticeExpire(tester);
  });

  testWidgets('tocar fuera no cierra el aviso; Atrás lo cierra sin guardar', (
    tester,
  ) async {
    await pumpFeed(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text(_title), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    expect(consents, isEmpty);
    expect(find.text(LocationNotice.usingDefaultCity.message), findsNothing);
  });

  testWidgets('si ya aceptó y el GPS no responde lo avisa sin preguntar', (
    tester,
  ) async {
    consents['sub-1'] = LocationConsent.granted;
    when(
      () => repository.getCurrentLocation(timeLimit: any(named: 'timeLimit')),
    ).thenAnswer((_) async => null);
    when(() => repository.getLastKnownLocation()).thenAnswer((_) async => null);

    await pumpFeed(tester);

    expect(find.text(_title), findsNothing);
    expect(find.text(LocationNotice.unavailable.message), findsOneWidget);
    await letNoticeExpire(tester);
  });

  testWidgets('a un organizador no se le pregunta', (tester) async {
    await pumpFeed(
      tester,
      authentication: _signedIn('org-1', isOrganizer: true),
    );

    expect(find.text(_title), findsNothing);
    verifyNever(() => repository.getConsent(any()));
  });
}
