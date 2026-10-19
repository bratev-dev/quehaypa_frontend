import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/organizer_calendar_controller.dart';
import '../molecules/calendar_date_strip.dart';
import '../molecules/calendar_period_selector.dart';

class OrganizerCalendarHeader extends ConsumerWidget {
  const OrganizerCalendarHeader({
    super.key,
    required this.dateScrollController,
    this.onCreateEvent,
  });

  final ScrollController dateScrollController;
  final ValueChanged<Rect>? onCreateEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerCalendarProvider);
    final createEventKey = GlobalKey();
    return Column(
      children: [
        Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onCreateEvent == null
                    ? null
                    : () {
                        final renderObject = createEventKey.currentContext
                            ?.findRenderObject();
                        if (renderObject is! RenderBox ||
                            !renderObject.hasSize) {
                          return;
                        }
                        final globalOrigin = renderObject.localToGlobal(
                          Offset.zero,
                        );
                        final overlayObject = Navigator.of(context)
                            .overlay
                            ?.context
                            .findRenderObject();
                        final localOrigin = overlayObject is RenderBox
                            ? overlayObject.globalToLocal(globalOrigin)
                            : globalOrigin;
                        onCreateEvent!(localOrigin & renderObject.size);
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  key: createEventKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB4A9A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Crear Evento',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SvgPicture.asset(
              'assets/images/organizer_dashboard_logo.svg',
              width: 290,
              height: 74,
            ),
            const SizedBox(height: 12),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              CalendarPeriodSelector(
                value: state.period,
                onChanged: (period) {
                  if (dateScrollController.hasClients) {
                    dateScrollController.jumpTo(0);
                  }
                  ref
                      .read(organizerCalendarProvider.notifier)
                      .selectPeriod(period);
                },
              ),
              const SizedBox(height: 14),
              CalendarDateStrip(
                date: state.selectedDate,
                period: state.period,
                scrollController: dateScrollController,
                onSelected: ref
                    .read(organizerCalendarProvider.notifier)
                    .selectDate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
