import 'package:flutter/material.dart';

class TimelineHourLabel extends StatelessWidget {
  const TimelineHourLabel({super.key, required this.hour});
  final int hour;

  @override
  Widget build(BuildContext context) => Text(
    '${hour.toString().padLeft(2, '0')}:00',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    ),
  );
}
