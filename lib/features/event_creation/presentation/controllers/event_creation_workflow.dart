import 'package:flutter/foundation.dart';

import '../../../../core/errors/failtures.dart';
import '../../../events/domain/usecases/event_use_cases.dart';
import '../../../events/presentation/controllers/event_providers.dart';
import '../../domain/created_event_preview.dart';
import 'event_creation_controller.dart';

/// Coordina los estados remotos del formulario sin conocer HTTP ni JSON.
class EventCreationWorkflow extends ChangeNotifier {
  EventCreationWorkflow(this.form, this.actions);
  final EventCreationController form;
  final EventUseCases actions;
  bool initializing = true;
  bool saving = false;
  String? initializationError;
  String? _pendingPublication;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    initializing = true;
    _notify();
    try {
      final data = await actions.loadCreation();
      if (_disposed) return;
      form.setCategories(data.categories);
      form.setBusinesses(data.businesses);
      if (data.draft != null) form.restoreDraft(data.draft!);
      initializationError = null;
    } catch (error) {
      if (_disposed) return;
      initializationError = eventError(error);
      form.reportError(initializationError!);
    } finally {
      initializing = false;
      _notify();
    }
  }

  Future<void> _persist() async {
    final id = await actions.saveDraft(form.draft());
    if (_disposed) return;
    form.draftId = id;
    for (var index = 0; index < form.attachments.length; index++) {
      final file = form.attachments[index];
      if (file.id == null) {
        final fileId = await actions.uploadAttachment(id, file);
        if (_disposed) return;
        form.markUploaded(index, fileId);
      }
    }
  }

  Future<bool> save() async {
    if (saving || initializing) return false;
    if (initializationError != null) {
      await load();
      return false;
    }
    if (_pendingPublication != null) {
      throw const ValidationFailure(
        'Vuelve a pulsar Publicar evento para comprobar la publicación pendiente.',
      );
    }
    saving = true;
    _notify();
    try {
      await _persist();
      return !_disposed;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<CreatedEventPreview?> publish() async {
    if (saving || initializing) return null;
    if (initializationError != null || form.categories.isEmpty) {
      await load();
      return null;
    }
    final validation = _pendingPublication == null ? form.validateData() : null;
    if (validation != null) throw ValidationFailure(validation);
    saving = true;
    _notify();
    try {
      if (_pendingPublication == null) {
        await _persist();
        if (_disposed) return null;
        _pendingPublication = form.draftId;
      }
      final event = await actions.publishDraft(_pendingPublication!);
      if (_disposed) return null;
      final start =
          DateTime.tryParse(event.startsAt ?? '') ?? form.draft().startsAt;
      if (start == null) {
        throw const ServerFailure(
          'El servidor devolvió una fecha de evento inválida.',
        );
      }
      return CreatedEventPreview(
        id: event.id,
        imageUrl: event.imageUrl,
        title: event.title,
        startsAt: start,
        endsAt:
            DateTime.tryParse(event.endsAt ?? '') ??
            form.eventEndDateTime ??
            start,
      );
    } catch (error) {
      if (error is ValidationFailure ||
          error is ConflictFailure ||
          error is UnauthorizedFailure) {
        _pendingPublication = null;
      }
      rethrow;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<Uint8List> attachment(String id) => actions.draftAttachment(id);
}
