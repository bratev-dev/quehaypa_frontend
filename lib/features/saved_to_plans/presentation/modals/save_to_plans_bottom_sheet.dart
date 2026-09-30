import 'package:flutter/material.dart';

import '../../../my_plans/presentation/organisms/create_plan_modal.dart';
import '../organisms/saved_to_plans_organism.dart';

void showSaveToPlansBottomSheet(
  BuildContext context, {
  required int eventId,
  required String eventTitle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212), // Fondo oscuro negro
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

      return Container(
        height: MediaQuery.of(sheetContext).size.height * 0.65,
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: SavedToPlansOrganism(
          eventId: eventId,
          eventTitle: eventTitle,
          onCreatePlan: () {
            Navigator.pop(sheetContext);
            showCreatePlanModal(context);
          },
        ),
      );
    },
  );
}
