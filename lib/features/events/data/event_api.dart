import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/network_providers.dart';
import '../../authentication/presentation/controllers/authentication_controller.dart';
import '../../preferences/data/models/event_seed_model.dart';
import '../../preferences/domain/entities/event_seed.dart';
import '../../event_creation/presentation/controllers/event_creation_controller.dart';

final eventApiProvider = Provider((ref) => EventApi(ref.watch(dioProvider)));
final organizerEventsProvider = FutureProvider.autoDispose<List<EventSeed>>((
  ref,
) {
  ref.watch(authenticationControllerProvider.select((s) => s.session));
  return ref.watch(eventApiProvider).mine();
});

class EventApi {
  const EventApi(this.dio);
  final Dio dio;

  String publicUrl(String path) =>
      Uri.parse(dio.options.baseUrl).resolve(path).toString();

  Future<String> shareText(int id) async {
    final event = await get(id);
    return [
      event.title,
      event.eventText,
      if (event.venue != null) event.venue!,
      if (event.isPaid) 'Evento con entrada de pago',
      event.description,
      ...event.links,
      ...event.attachments.map((f) => '${f.name}: ${publicUrl(f.url)}'),
    ].where((s) => s.isNotEmpty).join('\n');
  }

  Future<Uint8List> draftAttachment(String id) async {
    final response = await dio.get<List<int>>(
      '/api/v1/events/draft/me/attachments/$id',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<List<EventBusiness>> businesses() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/businesses/me',
    );
    final values = (response.data!['data'] as List).cast<Map>();
    if (values.isEmpty) {
      // ponytail: negocio ficticio para la demo; retirar esta creación al conectar el CRUD de negocios.
      final created = await dio.post<Map<String, dynamic>>(
        '/api/v1/businesses',
        data: {
          'name': 'Negocio demo',
          'nit': 'DEMO-SIN-VALIDEZ-FISCAL',
          'city': 'Bogotá',
          'description': 'Negocio de prueba para el flujo de demostración.',
        },
      );
      final business = created.data!['data'] as Map;
      return [
        EventBusiness(
          id: business['id'].toString(),
          name: business['name'] as String,
        ),
      ];
    }
    return values
        .map(
          (b) =>
              EventBusiness(id: b['id'].toString(), name: b['name'] as String),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> draft() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/events/draft/me',
    );
    final value = response.data!['data'];
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  Future<String> saveDraft(
    String? id,
    Map<String, dynamic> fields,
    List<String> attachmentIds,
  ) async {
    final response = await dio.put<Map<String, dynamic>>(
      '/api/v1/events/draft/me',
      data: {'id': id, 'fields': fields, 'attachmentIds': attachmentIds},
    );
    return (response.data!['data'] as Map)['id'] as String;
  }

  Future<String> uploadAttachment(String draftId, EventAttachment file) async {
    if (file.bytes == null && file.path == null) {
      throw StateError('Selecciona nuevamente el archivo ${file.name}.');
    }
    final multipart = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : await MultipartFile.fromFile(file.path!, filename: file.name);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/v1/events/draft/me/attachments',
      queryParameters: {'draftId': draftId},
      data: FormData.fromMap({'file': multipart}),
      options: Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return (response.data!['data'] as Map)['id'] as String;
  }

  Future<EventSeed> publishDraft(String id) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/v1/events/draft/me/publish',
      data: {'draftId': id},
    );
    return EventSeedModel.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    ).toEntity();
  }

  Future<List<String>> categories() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/business-categories',
    );
    return (response.data!['data'] as List)
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .toList();
  }

  Future<List<EventSeed>> mine() async {
    final response = await dio.get<Map<String, dynamic>>('/api/v1/events/me');
    return (response.data!['data'] as List)
        .map(
          (e) =>
              EventSeedModel.fromJson(Map<String, dynamic>.from(e as Map))
                  .toEntity(),
        )
        .toList();
  }

  Future<EventSeed> get(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/api/v1/events/$id');
    return EventSeedModel.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    ).toEntity();
  }

  Future<EventSeed> publish(
    Map<String, dynamic> event, {
    Uint8List? image,
    String? filename,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/v1/events',
      data: FormData.fromMap({
        'event': MultipartFile.fromString(
          jsonEncode(event),
          contentType: DioMediaType('application', 'json'),
        ),
        if (image != null)
          'image': MultipartFile.fromBytes(
            image,
            filename: filename ?? 'portada.jpg',
          ),
      }),
    );
    return EventSeedModel.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    ).toEntity();
  }

  Future<bool> registration(int id) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/events/$id/registration/me',
    );
    return (response.data!['data'] as Map)['registered'] == true;
  }

  Future<void> setRegistered(int id, bool registered) async {
    if (registered) {
      await dio.post<dynamic>('/api/v1/events/$id/registration/me');
    } else {
      await dio.delete<dynamic>('/api/v1/events/$id/registration/me');
    }
  }
}

String eventError(Object error) {
  if (error is StateError) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final status = error.response?.statusCode;
    if (status == 401) return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    if (status == 403) {
      return 'Tu cuenta no tiene permiso para realizar esta acción.';
    }
    if (status == 404) return 'El evento ya no está disponible.';
    if (status == 413) return 'Cada archivo debe tener como máximo 50 MB.';
    if (status != null) {
      return 'El servidor no pudo completar la operación (HTTP $status). Inténtalo de nuevo.';
    }
    return 'No pudimos conectar con el servidor. Revisa tu conexión a internet e inténtalo de nuevo.';
  }
  return 'No pudimos completar la operación. Inténtalo de nuevo.';
}
