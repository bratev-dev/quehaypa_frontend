import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/auth_interceptor.dart';
import 'package:frontend/core/security/secure_storage.dart';
import 'package:frontend/core/security/session_invalidator.dart';
import 'package:frontend/core/security/session_refresher.dart';
import 'package:frontend/core/security/token_manager.dart';

import '../../helpers/fake_http_adapter.dart';

class _FakeTokenManager extends TokenManager {
  String? access;

  _FakeTokenManager(this.access) : super(storage: SecureStorage());

  @override
  Future<String?> getAccessToken() async => access;
}

class _FakeRefresher implements SessionRefresher {
  final String? Function() onRefresh;
  int calls = 0;

  _FakeRefresher(this.onRefresh);

  @override
  Future<String?> refreshAccessToken() async {
    calls++;
    return onRefresh();
  }
}

class _FakeInvalidator implements SessionInvalidator {
  int calls = 0;

  @override
  Future<void> invalidateSession() async => calls++;
}

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;
  late _FakeInvalidator invalidator;

  Dio build({required String? token, required String? Function() refresh}) {
    adapter = FakeHttpAdapter();
    dio = dioWith(adapter);
    invalidator = _FakeInvalidator();
    final tokenManager = _FakeTokenManager(token);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenManager: tokenManager,
        // Como el repositorio real: el token refrescado queda guardado antes de
        // devolverse, y el reintento lo toma de nuevo en onRequest.
        sessionRefresher: _FakeRefresher(() {
          final refreshed = refresh();
          if (refreshed != null) tokenManager.access = refreshed;
          return refreshed;
        }),
        sessionInvalidator: invalidator,
      ),
    );
    return dio;
  }

  test('agrega el Bearer a cada petición cuando hay token', () async {
    build(token: 'abc', refresh: () => null);
    adapter.reply = const FakeReply(200, {'ok': true});

    await dio.get<dynamic>('/api/v1/regular-users/me');

    expect(adapter.last.headers['Authorization'], 'Bearer abc');
  });

  test('sin token no agrega el encabezado Authorization', () async {
    build(token: null, refresh: () => null);
    adapter.reply = const FakeReply(200, {'ok': true});

    await dio.get<dynamic>('/api/v1/interests');

    expect(adapter.last.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'ante un 401 refresca el token y reintenta la petición una vez',
    () async {
      build(token: 'viejo', refresh: () => 'nuevo');
      adapter.queue.addAll([
        const FakeReply(401, {'message': 'expirado'}),
        const FakeReply(200, {'ok': true}),
      ]);

      final response = await dio.get<dynamic>('/api/v1/regular-users/me');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(adapter.last.headers['Authorization'], 'Bearer nuevo');
      expect(invalidator.calls, 0);
    },
  );

  test(
    'si el refresco no devuelve token invalida la sesión y propaga el 401',
    () async {
      build(token: 'viejo', refresh: () => null);
      adapter.reply = const FakeReply(401, {'message': 'expirado'});

      await expectLater(
        dio.get<dynamic>('/api/v1/regular-users/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(invalidator.calls, 1);
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'si el refresco lanza error se trata como sin token e invalida la sesión',
    () async {
      build(token: 'viejo', refresh: () => throw Exception('Keycloak caído'));
      adapter.reply = const FakeReply(401);

      await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
      expect(invalidator.calls, 1);
    },
  );

  test('si el reintento vuelve a fallar invalida la sesión y no reintenta de nuevo', () async {
    build(token: 'viejo', refresh: () => 'nuevo');
    adapter.reply = const FakeReply(401);

    await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
    expect(adapter.requests, hasLength(2));
    expect(invalidator.calls, 1);
  });

  test('reenvía multipart después de renovar el token', () async {
    build(token: 'viejo', refresh: () => 'nuevo');
    adapter.queue.addAll([
      const FakeReply(401),
      const FakeReply(201, {'ok': true}),
    ]);
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes([1, 2, 3], filename: 'cover.png'),
    });
    final response = await dio.post<dynamic>('/api/v1/events', data: form);
    expect(response.statusCode, 201);
    expect(adapter.requests, hasLength(2));
    expect(identical(adapter.requests.first.data, adapter.last.data), isFalse);
    expect(invalidator.calls, 0);
  });

  test(
    'un 503 después de renovar conserva la sesión y el error real',
    () async {
      build(token: 'viejo', refresh: () => 'nuevo');
      adapter.queue.addAll([
        const FakeReply(401),
        const FakeReply(503, {'message': 'Discovery no disponible'}),
      ]);
      await expectLater(
        dio.post<dynamic>('/api/v1/events'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );
      expect(invalidator.calls, 0);
    },
  );

  test('errores distintos de 401 pasan sin refrescar', () async {
    build(token: 'abc', refresh: () => 'nuevo');
    adapter.reply = const FakeReply(500, {'message': 'error'});

    await expectLater(
      dio.get<dynamic>('/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
    expect(invalidator.calls, 0);
  });
}
