import '../../../event_creation/domain/created_event_preview.dart';

enum CalendarPeriod { day, month, year }

class OrganizerCalendarState {
  const OrganizerCalendarState({
    required DateTime selectedDate,
    CalendarPeriod period = CalendarPeriod.day,
    bool isLoading = false,
    List<CreatedEventPreview>? createdEvents,
  }) : this._(selectedDate, period, isLoading, createdEvents);

  const OrganizerCalendarState._(
    this.selectedDate,
    this.period,
    this.isLoading,
    this._createdEvents,
  );

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
