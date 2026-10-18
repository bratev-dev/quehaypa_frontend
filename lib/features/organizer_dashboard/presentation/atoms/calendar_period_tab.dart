import 'package:flutter/material.dart';

class CalendarPeriodTab extends StatelessWidget {
  const CalendarPeriodTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF282828) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF002AFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
  );
}
