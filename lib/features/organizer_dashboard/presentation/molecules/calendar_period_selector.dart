import 'package:flutter/material.dart';

import '../atoms/calendar_period_tab.dart';
import '../controllers/organizer_calendar_state.dart';

class CalendarPeriodSelector extends StatelessWidget {
  const CalendarPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final CalendarPeriod value;
  final ValueChanged<CalendarPeriod> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 41,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF282828),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          for (final period in CalendarPeriod.values)
            CalendarPeriodTab(
              label: switch (period) {
                CalendarPeriod.day => 'día',
                CalendarPeriod.month => 'mes',
                CalendarPeriod.year => 'año',
              },
              selected: value == period,
              onTap: () => onChanged(period),
            ),
        ],
      ),
    ),
  );
}
