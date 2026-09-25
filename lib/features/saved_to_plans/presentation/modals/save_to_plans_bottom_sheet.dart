import 'package:flutter/material.dart';

import '../../../my_plans/presentation/organisms/create_plan_modal.dart';
import '../organisms/saved_to_plans_organism.dart';

void showSaveToPlansBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212), // Fondo oscuro negro
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: SavedToPlansOrganism(
          onCreatePlan: () {
            Navigator.pop(context);
            showCreatePlanModal(context);
          },
        ),
      );
    },
  );
}
