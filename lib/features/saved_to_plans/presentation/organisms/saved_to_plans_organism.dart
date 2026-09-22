import 'package:flutter/material.dart';

import '../molecules/save_header_molecule.dart';
import '../molecules/save_to_plan_row_molecule.dart';
import '../atoms/search_input_atom.dart';

class SavedToPlansOrganism extends StatefulWidget {
  final VoidCallback onCreatePlan;

  const SavedToPlansOrganism({super.key, required this.onCreatePlan});

  @override
  State<SavedToPlansOrganism> createState() => _SavedToPlansOrganismState();
}

class _SavedToPlansOrganismState extends State<SavedToPlansOrganism> {
  // Simulando lista de planes del usuario
  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'P0',
      'details': '2 eventos, 1 establecimiento, 3 lugares',
      'selected': true,
    },
    {
      'name': 'P1',
      'details': '2 eventos, 1 establecimiento, 3 lugares',
      'selected': false,
    },
    {
      'name': 'P2',
      'details': '2 eventos, 1 establecimiento, 3 lugares',
      'selected': false,
    },
    {
      'name': 'P3',
      'details': '2 eventos, 1 establecimiento, 3 lugares',
      'selected': false,
    },
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredPlans = _plans
        .where(
          (plan) =>
              plan['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaveHeaderMolecule(onCreatePlan: widget.onCreatePlan),
        const SizedBox(height: 16),
        SearchInputAtom(
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: filteredPlans.length,
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];
              return SaveToPlanRowMolecule(
                planName: plan['name'],
                details: plan['details'],
                isSelected: plan['selected'],
                onToggle: () {
                  setState(() {
                    plan['selected'] = !plan['selected'];
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
