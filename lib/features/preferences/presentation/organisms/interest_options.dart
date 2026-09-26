import 'package:flutter/material.dart';

import '../../../authentication/presentation/atoms/interest_chip.dart';

class InterestOptions extends StatelessWidget {
  const InterestOptions({
    super.key,
    required this.catalog,
    required this.selected,
    required this.onToggle,
  });

  final List<String> catalog;
  final Iterable<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      for (final interest in catalog)
        InterestChip(
          label: interest,
          isSelected: selected.contains(interest),
          onTap: () => onToggle(interest),
        ),
    ],
  );
}
