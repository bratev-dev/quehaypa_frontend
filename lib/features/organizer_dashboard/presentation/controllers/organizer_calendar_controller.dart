import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../event_creation/domain/created_event_preview.dart';
import 'organizer_calendar_state.dart';

final organizerCalendarProvider =
    NotifierProvider<OrganizerCalendarController, OrganizerCalendarState>(
      OrganizerCalendarController.new,
    );

class OrganizerCalendarController extends Notifier<OrganizerCalendarState> {
  @override
  OrganizerCalendarState build() =>
      OrganizerCalendarState(selectedDate: DateTime(2026, 6, 1));

  void selectPeriod(CalendarPeriod period) {
    state = state.copyWith(period: period);
  }

  void showCreatedEvent(CreatedEventPreview event) {
    state = state.copyWith(
      selectedDate: DateTime(
        event.startsAt.year,
        event.startsAt.month,
        event.startsAt.day,
      ),
      period: CalendarPeriod.day,
      isLoading: false,
      createdEvents: List<CreatedEventPreview>.unmodifiable([
        ...state.createdEvents,
        event,
      ]),
    );
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (ref.mounted) state = state.copyWith(isLoading: false);
  }
}
