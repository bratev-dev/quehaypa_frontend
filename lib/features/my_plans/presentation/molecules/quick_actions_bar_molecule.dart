import 'package:flutter/material.dart';

import '../atoms/plan_action_icon_atom.dart';

class QuickActionsBarMolecule extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback? onAddFolder;
  final VoidCallback? onDelete;

  const QuickActionsBarMolecule({
    super.key,
    this.onShare,
    this.onAddFolder,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlanActionIconAtom(
          icon: Icons.subdirectory_arrow_right_rounded,
          onTap: onShare ?? () {},
        ),
        const SizedBox(width: 16),
        PlanActionIconAtom(
          icon: Icons.create_new_folder_outlined,
          onTap: onAddFolder ?? () {},
        ),
        const SizedBox(width: 16),
        PlanActionIconAtom(
          icon: Icons.delete_outline_rounded,
          onTap: onDelete ?? () {},
        ),
      ],
    );
  }
}
