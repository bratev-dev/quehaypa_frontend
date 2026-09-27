import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/auth_session.dart';

String token(Map<String, dynamic> claims) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.signature';

void main() {
  test('obtiene nombre y apellidos de Keycloak para el perfil', () {
    final session = AuthSession(
      accessToken: 'access',
      idToken: token({'given_name': 'Ana María', 'family_name': 'Ruiz Pérez'}),
    );
    expect(session.firstName, 'Ana María');
    expect(session.lastName, 'Ruiz Pérez');
  });

  test('los nombres usan access token si faltan en el id token', () {
    final session = AuthSession(
      accessToken: token({'given_name': 'Ana', 'family_name': 'Ruiz'}),
      idToken: token({'email': 'ana@test.com'}),
    );
    expect(session.firstName, 'Ana');
    expect(session.lastName, 'Ruiz');
  });

  test('sin nombres la identidad no inventa ni divide el nombre completo', () {
    final session = AuthSession(
      accessToken: token({'name': 'Ana María Ruiz Pérez'}),
    );
    expect(session.firstName, isEmpty);
    expect(session.lastName, isEmpty);
  });
  test('obtiene correo y usuario de la identidad de Keycloak', () {
    final session = AuthSession(
      accessToken: token({'email': 'access@test.com'}),
      idToken: token({'email': 'ana@test.com', 'preferred_username': 'ana'}),
    );
    expect(session.email, 'ana@test.com');
    expect(session.username, 'ana');
  });

  test('usa access token si el id token no aporta el dato', () {
    final session = AuthSession(
      accessToken: token({'email': 'ana@test.com'}),
      idToken: 'token-malformado',
    );
    expect(session.email, 'ana@test.com');
    expect(session.username, isEmpty);
  });

  test('tokens inválidos no generan excepciones en el formulario', () {
    const session = AuthSession(accessToken: 'header.@@@.signature');
    expect(session.email, isEmpty);
    expect(session.username, isEmpty);
  });
}
