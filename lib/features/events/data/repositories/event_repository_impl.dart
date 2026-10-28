import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/failtures.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../../domain/entities/event_draft.dart';
import '../../domain/repositories/event_repository.dart';
import '../event_api.dart';
import '../models/event_draft_model.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this.remote);
  final EventApi remote;

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : null;
      final status = error.response?.statusCode;
      if (status == null) {
        throw const NetworkFailure(
          'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
      if (status == 401 || status == 403) {
        throw UnauthorizedFailure(
          message ?? 'Tu sesión no permite realizar esta acción.',
        );
      }
      if (status == 409) {
        throw ConflictFailure(
          message ?? 'La información cambió. Vuelve a intentarlo.',
        );
      }
      if (status == 400 || status == 413) {
        throw ValidationFailure(
          message ?? 'Revisa los datos y el tamaño de los archivos.',
        );
      }
      throw ServerFailure(
        message ??
            'El servidor no pudo completar la operación (HTTP $status). Inténtalo de nuevo.',
      );
    } on Failure {
      rethrow;
    } on StateError catch (error) {
      throw ValidationFailure(error.message);
    } catch (_) {
      throw const ServerFailure(
        'La respuesta del servidor no es válida. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<List<String>> categories() => _request(remote.categories);
  @override
  Future<List<EventBusiness>> businesses() => _request(remote.businesses);
  @override
  Future<EventDraft?> draft() => _request(() async {
    final value = await remote.draft();
    return value == null ? null : EventDraftModel.fromJson(value);
  });
  @override
  Future<String> saveDraft(EventDraft draft) => _request(
    () => remote.saveDraft(
      draft.id,
      EventDraftModel.fields(draft),
      draft.attachments.map((file) => file.id).whereType<String>().toList(),
    ),
  );
  @override
  Future<String> uploadAttachment(String id, EventAttachment file) =>
      _request(() => remote.uploadAttachment(id, file));
  @override
  Future<Uint8List> draftAttachment(String id) =>
      _request(() => remote.draftAttachment(id));
  @override
  Future<EventSeed> publishDraft(String id) =>
      _request(() => remote.publishDraft(id));
  @override
  Future<List<EventSeed>> mine() => _request(remote.mine);
  @override
  Future<String> shareText(int id) => _request(() => remote.shareText(id));
}
