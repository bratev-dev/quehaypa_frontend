import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/data/models/auth_session_model.dart';

String token(Map<String, dynamic> claims) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.signature';

void main() {
  test(
    'el rol del access token orienta la navegación y no el del id token',
    () {
      final session = AuthSessionModel(
        accessToken: token({
          'realm_access': {
            'roles': ['ROLE_ORGANIZER'],
          },
        }),
      ).toEntity();
      expect(session.isOrganizer, isTrue);
      final regular = AuthSessionModel(
        accessToken: token({
          'realm_access': {
            'roles': ['ROLE_USER'],
          },
        }),
        idToken: token({
          'realm_access': {
            'roles': ['ROLE_ORGANIZER'],
          },
        }),
      ).toEntity();
      expect(regular.isOrganizer, isFalse);
    },
  );
  test('obtiene nombre y apellidos de Keycloak para el perfil', () {
    final session = AuthSessionModel(
      accessToken: 'access',
      idToken: token({'given_name': 'Ana María', 'family_name': 'Ruiz Pérez'}),
    ).toEntity();
    expect(session.firstName, 'Ana María');
    expect(session.lastName, 'Ruiz Pérez');
  });

  test('los nombres usan access token si faltan en el id token', () {
    final session = AuthSessionModel(
      accessToken: token({'given_name': 'Ana', 'family_name': 'Ruiz'}),
      idToken: token({'email': 'ana@test.com'}),
    ).toEntity();
    expect(session.firstName, 'Ana');
    expect(session.lastName, 'Ruiz');
  });

  test('sin nombres la identidad no inventa ni divide el nombre completo', () {
    final session = AuthSessionModel(
      accessToken: token({'name': 'Ana María Ruiz Pérez'}),
    ).toEntity();
    expect(session.firstName, isEmpty);
    expect(session.lastName, isEmpty);
  });
  test('obtiene correo y usuario de la identidad de Keycloak', () {
    final session = AuthSessionModel(
      accessToken: token({'email': 'access@test.com'}),
      idToken: token({'email': 'ana@test.com', 'preferred_username': 'ana'}),
    ).toEntity();
    expect(session.email, 'ana@test.com');
    expect(session.username, 'ana');
  });

  test('usa access token si el id token no aporta el dato', () {
    final session = AuthSessionModel(
      accessToken: token({'email': 'ana@test.com'}),
      idToken: 'token-malformado',
    ).toEntity();
    expect(session.email, 'ana@test.com');
    expect(session.username, isEmpty);
  });

  test('obtiene el identificador de la cuenta (sub)', () {
    final session = AuthSessionModel(
      accessToken: token({'sub': 'access-sub'}),
      idToken: token({'sub': 'f3a1c2d4-uuid'}),
    ).toEntity();
    expect(session.subject, 'f3a1c2d4-uuid');
  });

  test('sin sub el identificador queda vacío', () {
    final session = AuthSessionModel(
      accessToken: token({'email': 'ana@test.com'}),
    ).toEntity();
    expect(session.subject, isEmpty);
  });

  test('tokens inválidos no generan excepciones en el formulario', () {
    final session = AuthSessionModel(accessToken: 'header.@@@.signature')
        .toEntity();
    expect(session.email, isEmpty);
    expect(session.username, isEmpty);
  });
}
