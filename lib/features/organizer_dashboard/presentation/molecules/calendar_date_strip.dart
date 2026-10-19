import 'package:flutter/material.dart';

import '../atoms/calendar_date_chip.dart';
import '../controllers/organizer_calendar_state.dart';

class CalendarDateStrip extends StatelessWidget {
  const CalendarDateStrip({
    super.key,
    required this.date,
    required this.period,
    required this.onSelected,
    this.scrollController,
  });

  final DateTime date;
  final CalendarPeriod period;
  final ValueChanged<DateTime> onSelected;
  final ScrollController? scrollController;

  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  static const selectionDuration = Duration(milliseconds: 320);
  static const selectionCurve = Curves.easeInOutCubic;
  static const double _chipWidth = 46;
  static const double _chipSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final firstDay = date.subtract(Duration(days: date.weekday - 1));
    final selectedIndex = switch (period) {
      CalendarPeriod.day => date.weekday - 1,
      CalendarPeriod.month || CalendarPeriod.year => 2,
    };
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 7 * _chipWidth + 6 * _chipSpacing,
          height: 64,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: selectionDuration,
                curve: selectionCurve,
                left: selectedIndex * (_chipWidth + _chipSpacing),
                top: 0,
                child: Container(
                  width: _chipWidth,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF002AFF),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < 7; index++) ...[
                    if (index > 0) const SizedBox(width: _chipSpacing),
                    _dateChip(firstDay, index),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateChip(DateTime firstDay, int index) {
    final itemDate = switch (period) {
      CalendarPeriod.day => firstDay.add(Duration(days: index)),
      CalendarPeriod.month => DateTime(date.year, date.month - 2 + index),
      CalendarPeriod.year => DateTime(date.year - 2 + index),
    };
    final selected = switch (period) {
      CalendarPeriod.day => DateUtils.isSameDay(date, itemDate),
      CalendarPeriod.month =>
        date.year == itemDate.year && date.month == itemDate.month,
      CalendarPeriod.year => date.year == itemDate.year,
    };
    return CalendarDateChip(
      topLabel: switch (period) {
        CalendarPeriod.day => _weekdays[itemDate.weekday - 1],
        CalendarPeriod.month => _months[itemDate.month - 1],
        CalendarPeriod.year => 'año',
      },
      bottomLabel: switch (period) {
        CalendarPeriod.day => '${itemDate.day}',
        CalendarPeriod.month => '${itemDate.month}',
        CalendarPeriod.year => '${itemDate.year}',
      },
      selected: selected,
      onTap: () {
        final controller = scrollController;
        if (controller != null && controller.hasClients) {
          final start = index * (_chipWidth + _chipSpacing);
          final end = start + _chipWidth;
          final visibleStart = controller.offset;
          final visibleEnd =
              visibleStart + controller.position.viewportDimension;
          if (start < visibleStart || end > visibleEnd) {
            final target = start < visibleStart
                ? start
                : end - controller.position.viewportDimension;
            controller.animateTo(
              target.clamp(0.0, controller.position.maxScrollExtent).toDouble(),
              duration: selectionDuration,
              curve: selectionCurve,
            );
          }
        }
        onSelected(itemDate);
      },
    );
  }
}
