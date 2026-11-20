import 'package:flutter/material.dart';

import '../event_creation_colors.dart';

class EventCreationToggle extends StatelessWidget {
  const EventCreationToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: EventCreationColors.hint,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: EventCreationColors.blue,
          activeTrackColor: EventCreationColors.activeSwitchTrack,
          inactiveThumbColor: const Color(0xFFDBE0ED),
          inactiveTrackColor: EventCreationColors.muted,
        ),
      ],
    ),
  );
}
