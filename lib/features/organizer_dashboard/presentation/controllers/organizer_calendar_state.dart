import '../../../event_creation/domain/created_event_preview.dart';

enum CalendarPeriod { day, month, year }

class OrganizerCalendarState {
  const OrganizerCalendarState({
    required this.selectedDate,
    this.period = CalendarPeriod.day,
    this.isLoading = false,
    List<CreatedEventPreview>? createdEvents,
  }) : _createdEvents = createdEvents;

  final DateTime selectedDate;
  final CalendarPeriod period;
  final bool isLoading;
  // An existing state instance may gain this field during Flutter hot reload.
  // Its new field starts as null until the provider creates the next state.
  final List<CreatedEventPreview>? _createdEvents;
  List<CreatedEventPreview> get createdEvents => _createdEvents ?? const [];

  OrganizerCalendarState copyWith({
    DateTime? selectedDate,
    CalendarPeriod? period,
    bool? isLoading,
    List<CreatedEventPreview>? createdEvents,
  }) => OrganizerCalendarState(
    selectedDate: selectedDate ?? this.selectedDate,
    period: period ?? this.period,
    isLoading: isLoading ?? this.isLoading,
    createdEvents: createdEvents ?? this.createdEvents,
  );
}
