import '../../domain/entities/event_draft.dart';

class EventDraftModel {
  static EventDraft fromJson(Map<String, dynamic> json) {
    final fields = Map<String, dynamic>.from(json['fields'] as Map);
    final event = Map<String, dynamic>.from(fields['event'] as Map? ?? {});
    return EventDraft(
      id: json['id'] as String,
      name: event['title'] as String? ?? '',
      category: event['category'] as String? ?? '',
      address: event['venue'] as String? ?? '',
      description: event['description'] as String? ?? '',
      day: fields['day'] as String? ?? '',
      month: fields['month'] as String? ?? '',
      year: fields['year'] as String? ?? '',
      step: fields['step'] as int? ?? 0,
      startHour: fields['startHour'] as int?,
      startMinute: fields['startMinute'] as int?,
      endHour: fields['endHour'] as int?,
      endMinute: fields['endMinute'] as int?,
      businessId: event['businessId'] as int?,
      isPaid: event['isPaid'] == true,
      adultsOnly: event['audience'] == 'ADULTS_ONLY',
      startsAt: DateTime.tryParse(event['startsAt'] as String? ?? ''),
      endsAt: DateTime.tryParse(event['endsAt'] as String? ?? ''),
      links: (event['links'] as List? ?? []).cast<String>(),
      attachments: (json['attachments'] as List? ?? [])
          .map(
            (file) => EventAttachment(
              id: file['id'] as String,
              name: file['name'] as String,
              sizeBytes: (file['sizeBytes'] as num).toInt(),
            ),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> fields(EventDraft draft) => {
    'day': draft.day,
    'month': draft.month,
    'year': draft.year,
    'step': draft.step,
    'startHour': draft.startHour,
    'startMinute': draft.startMinute,
    'endHour': draft.endHour,
    'endMinute': draft.endMinute,
    'event': {
      'title': draft.name.trim(),
      'description': draft.description.trim(),
      'category': draft.category,
      'venue': draft.address.trim(),
      'businessId': draft.businessId,
      'isPaid': draft.isPaid,
      'links': draft.links,
      'audience': draft.adultsOnly ? 'ADULTS_ONLY' : 'ALL_AGES',
      'startsAt': draft.startsAt?.toIso8601String(),
      'endsAt': draft.endsAt?.toIso8601String(),
    },
  };
}
