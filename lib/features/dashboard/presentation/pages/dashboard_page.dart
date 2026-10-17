import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../templates/dashboard_templates.dart';
import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrganizer = ref.watch(
      authenticationControllerProvider.select((state) => state.isOrganizer),
    );
    return isOrganizer
        ? const OrganizerDashboardPage()
        : const DashboardTemplate();
  }
}
