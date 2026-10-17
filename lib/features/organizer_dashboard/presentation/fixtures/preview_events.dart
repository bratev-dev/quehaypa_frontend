class PreviewCalendarEvent {
  const PreviewCalendarEvent({
    required this.title,
    required this.startHour,
    required this.durationHours,
    required this.row,
    required this.attendees,
  });

  final String title;
  final int startHour;
  final int durationHours;
  final int row;
  final int attendees;
}

const previewEvents = <PreviewCalendarEvent>[
  PreviewCalendarEvent(
    title: 'Congreso Gastronómico',
    startHour: 7,
    durationHours: 1,
    row: 0,
    attendees: 200,
  ),
  PreviewCalendarEvent(
    title: 'Diseño al Halloween',
    startHour: 12,
    durationHours: 2,
    row: 0,
    attendees: 20,
  ),
  PreviewCalendarEvent(
    title: 'Congreso AMD',
    startHour: 8,
    durationHours: 2,
    row: 1,
    attendees: 20,
  ),
];
