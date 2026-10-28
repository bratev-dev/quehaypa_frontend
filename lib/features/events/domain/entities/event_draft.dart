import 'dart:typed_data';

class EventBusiness {
  const EventBusiness({required this.id, required this.name});
  final String id;
  final String name;
}

class EventAttachment {
  const EventAttachment({
    required this.name,
    required this.sizeBytes,
    this.bytes,
    this.id,
    this.path,
  });
  final String name;
  final int sizeBytes;
  final Uint8List? bytes;
  final String? id;
  final String? path;
  String get extension => name.split('.').last.toLowerCase();
}

/// Valores del formulario, incluidos los incompletos; no conoce el contrato JSON.
class EventDraft {
  const EventDraft({
    this.id,
    this.name = '',
    this.category = '',
    this.address = '',
    this.description = '',
    this.day = '',
    this.month = '',
    this.year = '',
    this.step = 0,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    this.startsAt,
    this.endsAt,
    this.businessId,
    this.isPaid = false,
    this.adultsOnly = false,
    this.links = const [],
    this.attachments = const [],
  });
  final String? id;
  final String name, category, address, description, day, month, year;
  final int step;
  final int? startHour, startMinute, endHour, endMinute, businessId;
  final DateTime? startsAt, endsAt;
  final bool isPaid, adultsOnly;
  final List<String> links;
  final List<EventAttachment> attachments;
}

class EventCreationData {
  const EventCreationData(this.categories, this.businesses, this.draft);
  final List<String> categories;
  final List<EventBusiness> businesses;
  final EventDraft? draft;
}
