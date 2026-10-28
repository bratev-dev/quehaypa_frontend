import 'dart:typed_data';

import '../../../preferences/domain/entities/event_seed.dart';
import '../entities/event_draft.dart';

abstract class EventRepository {
  Future<List<String>> categories();
  Future<List<EventBusiness>> businesses();
  Future<EventDraft?> draft();
  Future<String> saveDraft(EventDraft draft);
  Future<String> uploadAttachment(String draftId, EventAttachment file);
  Future<Uint8List> draftAttachment(String id);
  Future<EventSeed> publishDraft(String id);
  Future<List<EventSeed>> mine();
  Future<String> shareText(int id);
}
