enum CalendarPeriod { day, month, year }

class OrganizerCalendarState {
  const OrganizerCalendarState({
    required this.selectedDate,
    this.period = CalendarPeriod.day,
    this.isLoading = false,
  });

  final DateTime selectedDate;
  final CalendarPeriod period;
  final bool isLoading;

  OrganizerCalendarState copyWith({
    DateTime? selectedDate,
    CalendarPeriod? period,
    bool? isLoading,
  }) => OrganizerCalendarState(
    selectedDate: selectedDate ?? this.selectedDate,
    period: period ?? this.period,
    isLoading: isLoading ?? this.isLoading,
  );
}
