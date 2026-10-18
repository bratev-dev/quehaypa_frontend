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

  @override
  Widget build(BuildContext context) {
    final firstDay = date.subtract(Duration(days: date.weekday - 1));
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
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
                final start = index * 54.0;
                final end = start + 46;
                final visibleStart = controller.offset;
                final visibleEnd =
                    visibleStart + controller.position.viewportDimension;
                if (start < visibleStart || end > visibleEnd) {
                  final target = start < visibleStart
                      ? start
                      : end - controller.position.viewportDimension;
                  controller.animateTo(
                    target
                        .clamp(0.0, controller.position.maxScrollExtent)
                        .toDouble(),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOutCubic,
                  );
                }
              }
              onSelected(itemDate);
            },
          );
        },
      ),
    );
  }
}
