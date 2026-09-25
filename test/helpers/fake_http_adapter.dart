import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta simulada para una petición: código HTTP + cuerpo JSON,
/// o un [error] de Dio (timeout, sin conexión) que se lanza tal cual.
class FakeReply {
  final int statusCode;
  final Object? body;
  final DioExceptionType? error;

  const FakeReply(this.statusCode, [this.body]) : error = null;

  const FakeReply.error(DioExceptionType this.error)
    : statusCode = 0,
      body = null;
}

/// Adaptador HTTP en memoria para probar datasources sin red.
///
/// Registra cada petición en [requests] y responde con [reply]. Con una
/// respuesta 4xx/5xx, Dio lanza su `DioException` real, así que se prueba el
/// mismo mapeo de errores que ocurre en la app.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeReply reply;
  final List<RequestOptions> requests = [];

  /// Respuestas en orden para peticiones sucesivas; cuando se agota, se usa [reply].
  final List<FakeReply> queue = [];

  FakeHttpAdapter([this.reply = const FakeReply(200, {'data': null})]);

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final current = queue.isNotEmpty ? queue.removeAt(0) : reply;
    final error = current.error;
    if (error != null) {
      throw DioException(requestOptions: options, type: error);
    }
    // Un cuerpo String viaja como texto plano (como un proxy o un error HTML);
    // cualquier otro valor viaja como JSON.
    final isText = current.body is String;
    return ResponseBody.fromString(
      isText ? current.body as String : jsonEncode(current.body),
      current.statusCode,
      headers: {
        Headers.contentTypeHeader: [
          isText ? Headers.textPlainContentType : Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Dio real apuntando a un host ficticio, con el adaptador falso.
Dio dioWith(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
