import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';
import '../../../plans/presentation/controllers/plans_state.dart';
import '../molecules/plan_card_molecule.dart';
import '../pages/plan_details_page.dart';

/// Grid de planes conectado al estado del controlador.
class MyPlansGridOrganism extends ConsumerStatefulWidget {
  const MyPlansGridOrganism({super.key});

  @override
  ConsumerState<MyPlansGridOrganism> createState() =>
      _MyPlansGridOrganismState();
}

class _MyPlansGridOrganismState extends ConsumerState<MyPlansGridOrganism> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plansControllerProvider);

    if ((state.status == PlansStatus.initial ||
            state.status == PlansStatus.loading) &&
        state.plans.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.92,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => const _PlanSkeletonCard(),
      );
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
    if (plans.isEmpty) {
      return const Align(
        // Compensa el encabezado para centrar el mensaje en la pantalla.
        alignment: Alignment(0, -0.22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 56, color: Colors.black87),
            SizedBox(height: 12),
            Text(
              'Aún no tienes planes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Crea uno y guarda los eventos que quieras vivir.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text('Toca el botón + para empezar.'),
          ],
        ),
      );
    }
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
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return PlanCardMolecule(
          title: plan.title,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlanDetailsPage(plan: plan),
            ),
          ),
          onViewMore: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlanDetailsPage(plan: plan),
            ),
          ),
        );
      },
    );
  }
}

class _PlanSkeletonCard extends StatefulWidget {
  const _PlanSkeletonCard();

  @override
  State<_PlanSkeletonCard> createState() => _PlanSkeletonCardState();
}

class _PlanSkeletonCardState extends State<_PlanSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (context, child) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white60, Colors.white, _pulse.value),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 14, width: double.infinity, color: Colors.black12),
        ],
      ),
    ),
  );
}
