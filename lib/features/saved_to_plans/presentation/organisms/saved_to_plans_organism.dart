import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';
import '../../../plans/presentation/controllers/plans_state.dart';
import '../molecules/save_header_molecule.dart';
import '../molecules/save_to_plan_row_molecule.dart';
import '../atoms/search_input_atom.dart';

/// Bottom-sheet Spotify conectado al backend: lista `GET /my-plans`
/// con buscador local. La selección es local (no hay endpoint de
/// "guardar evento en plan" aún); al crear, delega en `onCreatePlan`.
class SavedToPlansOrganism extends ConsumerStatefulWidget {
  final VoidCallback onCreatePlan;

  const SavedToPlansOrganism({super.key, required this.onCreatePlan});

  @override
  ConsumerState<SavedToPlansOrganism> createState() =>
      _SavedToPlansOrganismState();
}

class _SavedToPlansOrganismState extends ConsumerState<SavedToPlansOrganism> {
  final Set<int> _selectedIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(plansControllerProvider.notifier).loadMyPlans(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plansControllerProvider);

    final filteredPlans = state.plans
        .where(
          (plan) =>
              plan.title.toLowerCase().contains(_searchQuery.toLowerCase()),
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
          child: switch (state.status) {
            PlansStatus.loading when state.plans.isEmpty => const Center(
              child: CircularProgressIndicator(),
            ),
            PlansStatus.error when state.plans.isEmpty => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ?? 'Error al cargar planes.',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(plansControllerProvider.notifier)
                        .loadMyPlans(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            _ when filteredPlans.isEmpty => const Center(
              child: Text(
                'No tienes planes aún. Crea el primero.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            _ => ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredPlans.length,
              itemBuilder: (context, index) {
                final plan = filteredPlans[index];
                final isSelected = _selectedIds.contains(plan.id);
                return SaveToPlanRowMolecule(
                  planName: plan.title,
                  details: plan.description.isEmpty
                      ? 'Plan #${plan.id}'
                      : plan.description,
                  isSelected: isSelected,
                  onToggle: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(plan.id);
                      } else {
                        _selectedIds.add(plan.id);
                      }
                    });
                  },
                );
              },
            ),
          },
        ),
      ],
    );
  }
}
