import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../fixtures/preview_events.dart';

class OrganizerEventCard extends StatelessWidget {
  const OrganizerEventCard({super.key, required this.event});
  final PreviewCalendarEvent event;

  @override
  Widget build(BuildContext context) => Container(
    width: 188,
    height: 171,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 103,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E6E6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                width: 33,
                height: 33,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB4A9A),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'Info',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF49BC7).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${event.startHour}:00 - ${event.startHour + event.durationHours}:00',
                    style: const TextStyle(
                      color: Color(0xFFEB4A9A),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 41,
              height: 21,
              child: Stack(
                children: [
                  for (var index = 0; index < 3; index++)
                    Positioned(
                      left: index * 10,
                      child: SvgPicture.asset(
                        'assets/images/organizer_avatar_${index + 1}.svg',
                        width: 20.465,
                        height: 20.465,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '+${event.attendees}',
              style: const TextStyle(color: Colors.black54, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}
