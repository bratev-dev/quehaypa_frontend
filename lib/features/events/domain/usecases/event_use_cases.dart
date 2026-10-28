import 'dart:typed_data';

import '../../../preferences/domain/entities/event_seed.dart';
import '../entities/event_draft.dart';
import '../repositories/event_repository.dart';

/// Acciones de la integración de eventos; las dependencias se inyectan por Riverpod.
class EventUseCases {
  const EventUseCases(this.repository);
  final EventRepository repository;
  Future<EventCreationData> loadCreation() async => EventCreationData(
    await repository.categories(),
    await repository.businesses(),
    await repository.draft(),
  );
  Future<String> saveDraft(EventDraft draft) => repository.saveDraft(draft);
  Future<String> uploadAttachment(String id, EventAttachment file) =>
      repository.uploadAttachment(id, file);
  Future<Uint8List> draftAttachment(String id) =>
      repository.draftAttachment(id);
  Future<EventSeed> publishDraft(String id) => repository.publishDraft(id);
  Future<List<EventSeed>> organizerEvents() => repository.mine();
  Future<String> shareEvent(int id) => repository.shareText(id);
}
