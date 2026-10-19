import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../event_creation/domain/created_event_preview.dart';
import '../atoms/timeline_hour_label.dart';
import '../controllers/organizer_calendar_controller.dart';
import '../fixtures/preview_events.dart';
import '../molecules/organizer_event_card.dart';
import '../molecules/organizer_event_skeleton.dart';

class OrganizerCalendarMap extends ConsumerStatefulWidget {
  const OrganizerCalendarMap({super.key});

  @override
  ConsumerState<OrganizerCalendarMap> createState() =>
      _OrganizerCalendarMapState();
}

class _OrganizerCalendarMapState extends ConsumerState<OrganizerCalendarMap> {
  static const double hourWidth = 76;
  static const double baseCanvasWidth = 14 * hourWidth;
  static const double baseCanvasHeight = 840;
  static const double hourHeaderHeight = 58;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  CreatedEventPreview? _lastFocusedEvent;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerCalendarProvider);
    final selectedDate = state.selectedDate;
    final hasFixtureEvents =
        selectedDate.year == 2026 &&
        selectedDate.month == 6 &&
        selectedDate.day == 1;
    final createdEvents = state.createdEvents
        .where((event) {
          final date = event.startsAt;
          return date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
        })
        .toList()
        .reversed
        .toList();

    var firstHour = 7;
    var lastHour = 20;
    for (final event in createdEvents) {
      firstHour = math.min(firstHour, event.startsAt.hour);
      lastHour = math.max(lastHour, event.startsAt.hour);
    }
    final hourCount = lastHour - firstHour + 1;
    final canvasWidth = createdEvents.isEmpty
        ? baseCanvasWidth
        : math.max(baseCanvasWidth, hourCount * hourWidth + 240);
    final totalRows = createdEvents.length + (hasFixtureEvents ? 2 : 0);
    final canvasHeight = math
        .max(baseCanvasHeight, hourHeaderHeight + 44 + totalRows * 202)
        .toDouble();

    if (createdEvents.isEmpty && _lastFocusedEvent != null) {
      _lastFocusedEvent = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _horizontalController.hasClients) {
          _horizontalController.jumpTo(0);
        }
      });
    }
    if (createdEvents.isNotEmpty &&
        !identical(_lastFocusedEvent, createdEvents.first)) {
      _lastFocusedEvent = createdEvents.first;
      final targetHour = createdEvents.first.startsAt.hour;
      final earliestHour = firstHour;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_horizontalController.hasClients) return;
        final target = (targetHour - earliestHour) * hourWidth - 24;
        _horizontalController.jumpTo(
          target
              .clamp(0.0, _horizontalController.position.maxScrollExtent)
              .toDouble(),
        );
        if (_verticalController.hasClients) _verticalController.jumpTo(0);
      });
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(41)),
      child: ColoredBox(
        color: const Color(0xFFFCD413),
        child: _calendarCanvas(
          isLoading: state.isLoading,
          hasFixtureEvents: hasFixtureEvents,
          createdEvents: createdEvents,
          firstHour: firstHour,
          hourCount: hourCount,
          canvasWidth: canvasWidth,
          canvasHeight: canvasHeight,
        ),
      ),
    );
  }

  Widget _calendarCanvas({
    required bool isLoading,
    required bool hasFixtureEvents,
    required List<CreatedEventPreview> createdEvents,
    required int firstHour,
    required int hourCount,
    required double canvasWidth,
    required double canvasHeight,
  }) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      controller: _horizontalController,
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
                  for (var index = 0; index < hourCount; index++) ...[
                    Positioned(
                      left: 34 + index * hourWidth,
                      top: 22,
                      child: TimelineHourLabel(hour: firstHour + index),
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
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight - hourHeaderHeight,
                  child: Stack(
                    children: [
                      for (var index = 0; index < hourCount; index++)
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
                      ] else ...[
                        for (
                          var index = 0;
                          index < createdEvents.length;
                          index++
                        )
                          Positioned(
                            left:
                                39 +
                                (createdEvents[index].startsAt.hour -
                                        firstHour +
                                        createdEvents[index].startsAt.minute /
                                            60) *
                                    hourWidth,
                            top: 44 + index * 202,
                            child: OrganizerEventCard(
                              event: PreviewCalendarEvent(
                                title: createdEvents[index].title,
                                startHour: createdEvents[index].startsAt.hour,
                                durationHours: 1,
                                row: index,
                                attendees: 0,
                                timeLabel: _timeLabel(createdEvents[index]),
                              ),
                            ),
                          ),
                        if (hasFixtureEvents)
                          for (final event in previewEvents)
                            Positioned(
                              left:
                                  39 +
                                  (event.startHour - firstHour) * hourWidth,
                              top:
                                  44 + (event.row + createdEvents.length) * 202,
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

  String _timeLabel(CreatedEventPreview event) {
    String format(DateTime time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final nextDay = DateUtils.dateOnly(event.endsAt)
        .isAfter(DateUtils.dateOnly(event.startsAt));
    return '${format(event.startsAt)} - ${format(event.endsAt)}${nextDay ? ' (+1 día)' : ''}';
  }
}
