import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/timeline_hour_label.dart';
import '../controllers/organizer_calendar_controller.dart';
import '../fixtures/preview_events.dart';
import '../molecules/organizer_event_card.dart';
import '../molecules/organizer_event_skeleton.dart';

class OrganizerCalendarMap extends ConsumerWidget {
  const OrganizerCalendarMap({super.key});

  static const double hourWidth = 76;
  static const double canvasWidth = 14 * hourWidth;
  static const double canvasHeight = 840;
  static const double hourHeaderHeight = 58;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerCalendarProvider);
    final hasPreview =
        state.selectedDate.year == 2026 &&
        state.selectedDate.month == 6 &&
        state.selectedDate.day == 1;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(41)),
      child: ColoredBox(
        color: const Color(0xFFFCD413),
        child: _calendarCanvas(state.isLoading, hasPreview),
      ),
    );
  }

  Widget _calendarCanvas(bool isLoading, bool hasPreview) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: canvasWidth,
        height: constraints.maxHeight,
        child: Column(
          children: [
            SizedBox(
              height: hourHeaderHeight,
              child: Stack(
                children: [
                  for (var index = 0; index < 14; index++) ...[
                    Positioned(
                      left: 34 + index * hourWidth,
                      top: 22,
                      child: TimelineHourLabel(hour: 7 + index),
                    ),
                    Positioned(
                      left: 53 + index * hourWidth,
                      top: 50,
                      child: const CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xFFFFE97D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight - hourHeaderHeight,
                  child: Stack(
                    children: [
                      for (var index = 0; index < 14; index++)
                        Positioned(
                          left: 55 + index * hourWidth,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: const Color(0xFFFFE97D),
                          ),
                        ),
                      if (isLoading) ...[
                        const Positioned(
                          left: 39,
                          top: 44,
                          child: OrganizerEventSkeleton(),
                        ),
                        const Positioned(
                          left: 115,
                          top: 246,
                          child: OrganizerEventSkeleton(),
                        ),
                      ] else if (hasPreview) ...[
                        for (final event in previewEvents)
                          Positioned(
                            left: 39 + (event.startHour - 7) * hourWidth,
                            top: 44 + event.row * 202,
                            child: OrganizerEventCard(event: event),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
