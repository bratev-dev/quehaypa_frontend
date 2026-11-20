import 'package:flutter/material.dart';

import '../templates/organizer_dashboard_template.dart';

class OrganizerDashboardPage extends StatelessWidget {
  const OrganizerDashboardPage({super.key, this.preview = false});

  final bool preview;

  @override
  Widget build(BuildContext context) =>
      OrganizerDashboardTemplate(preview: preview);
}
