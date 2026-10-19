import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/organizer_dashboard/presentation/controllers/organizer_calendar_controller.dart';
import 'package:frontend/features/organizer_dashboard/presentation/controllers/organizer_calendar_state.dart';

void main() {
  test('inicia el calendario en el primer día de la vista previa', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(organizerCalendarProvider);
    expect(state.selectedDate, DateTime(2026, 6, 1));
    expect(state.period, CalendarPeriod.day);
    expect(state.isLoading, isFalse);
    expect(state.createdEvents, isEmpty);
  });

  test('cambia el período sin perder la fecha seleccionada', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(organizerCalendarProvider.notifier)
        .selectPeriod(CalendarPeriod.month);
    final state = container.read(organizerCalendarProvider);
    expect(state.period, CalendarPeriod.month);
    expect(state.selectedDate, DateTime(2026, 6, 1));
    expect(state.isLoading, isFalse);
  });

  test(
    'la nueva fecha muestra carga y después vuelve al estado normal',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final operation = container
          .read(organizerCalendarProvider.notifier)
          .selectDate(DateTime(2026, 6, 2));
      expect(
        container.read(organizerCalendarProvider).selectedDate,
        DateTime(2026, 6, 2),
      );
      expect(container.read(organizerCalendarProvider).isLoading, isTrue);

      await operation;
      expect(container.read(organizerCalendarProvider).isLoading, isFalse);
    },
  );

  test('copyWith conserva valores no modificados y permite cambiar todos', () {
    final initial = OrganizerCalendarState(selectedDate: DateTime(2026, 6, 1));
    final year = initial.copyWith(period: CalendarPeriod.year);
    expect(year.selectedDate, initial.selectedDate);
    expect(year.isLoading, isFalse);
    expect(year.period, CalendarPeriod.year);

    final loading = year.copyWith(
      selectedDate: DateTime(2027, 1, 1),
      isLoading: true,
    );
    expect(loading.selectedDate, DateTime(2027, 1, 1));
    expect(loading.period, CalendarPeriod.year);
    expect(loading.isLoading, isTrue);
    expect(loading.createdEvents, isEmpty);
  });

  test('tolera una lista de eventos ausente en un estado previo', () {
    final state = OrganizerCalendarState(
      selectedDate: DateTime(2026, 6, 1),
      createdEvents: null,
    );
    expect(state.createdEvents, isEmpty);
    expect(state.copyWith(period: CalendarPeriod.month).createdEvents, isEmpty);
  });
}
