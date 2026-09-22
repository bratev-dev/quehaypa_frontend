import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';
import '../../../plans/presentation/controllers/plans_state.dart';
import '../molecules/plan_card_molecule.dart';
import 'create_plan_modal.dart'; // Importa tu modal de creación

/// Grid Spotify conectado al backend: lee `GET /my-plans` vía
/// PlansController y elimina con `DELETE /{id}/delete` (optimista +
/// recarga). Mantiene la UX original (add-card + swipe + UNDO).
class MyPlansGridOrganism extends ConsumerStatefulWidget {
  const MyPlansGridOrganism({super.key});

  @override
  ConsumerState<MyPlansGridOrganism> createState() =>
      _MyPlansGridOrganismState();
}

class _MyPlansGridOrganismState extends ConsumerState<MyPlansGridOrganism> {
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

    if (state.status == PlansStatus.loading && state.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == PlansStatus.error && state.plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.errorMessage ?? 'Error al cargar planes.',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  ref.read(plansControllerProvider.notifier).loadMyPlans(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final plans = state.plans;
    final totalCount = plans.length + 1;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Blindaje B: celda más alta (0.92) como colchón base; la tarjeta
        // además reparte el alto con Flexible, así que ni fuentes grandes
        // ni títulos de 255 chars desbordan los ~3.2px originales.
        childAspectRatio: 0.92,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == plans.length) {
          return PlanCardMolecule(
            isAddCard: true,
            title: '',
            onTap: () {
              showCreatePlanModal(context);
            },
            onViewMore: () {},
          );
        }

        final plan = plans[index];

        return Dismissible(
          key: ValueKey(plan.id),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          onDismissed: (direction) async {
            final notifier = ref.read(plansControllerProvider.notifier);
            final ok = await notifier.deletePlan(plan.id);

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  content: Text(
                    'Plan "${plan.title}" eliminado',
                    style: const TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  content: Text(
                    ref.read(plansControllerProvider).errorMessage ??
                        'No fue posible eliminar el plan.',
                    style: const TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: PlanCardMolecule(
            title: plan.title,
            onTap: () {
              // Lógica al tocar la tarjeta del plan
            },
            onViewMore: () {
              // Lógica al tocar "Ver más"
            },
          ),
        );
      },
    );
  }
}
