import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../plans/domain/entities/plan.dart';
import '../../../plans/presentation/controllers/plans_controller.dart';
import '../molecules/plan_actions_speed_dial.dart';
import '../organisms/create_plan_modal.dart';
import '../templates/my_plans_template.dart';

/// Página canónica de Mis Planes (UI Spotify + backend real).
/// Dispara `GET /my-plans` al entrar para que el grid y el bottom-sheet
/// siempre vean datos frescos.
class MyPlansPage extends ConsumerStatefulWidget {
  const MyPlansPage({super.key});

  @override
  ConsumerState<MyPlansPage> createState() => _MyPlansPageState();
}

class _MyPlansPageState extends ConsumerState<MyPlansPage> {
  bool _actionsOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(plansControllerProvider.notifier).loadMyPlans(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansControllerProvider).plans;
    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      body: const MyPlansTemplate(),
      floatingActionButton: Padding(
        // El navbar de Dashboard se superpone a esta página. Su cápsula
        // comienza a unos 130 dp del borde inferior; dejamos 16 dp entre ambos.
        padding: const EdgeInsets.only(bottom: 130),
        child: PlanActionsSpeedDial(
          isOpen: _actionsOpen,
          hasPlans: plans.isNotEmpty,
          hasOwnedPlans: plans.any((plan) => plan.isCreator),
          onToggle: () => setState(() => _actionsOpen = !_actionsOpen),
          onCreate: () {
            setState(() => _actionsOpen = false);
            showCreatePlanModal(context);
          },
          onShare: () {
            setState(() => _actionsOpen = false);
            _sharePlan(plans);
          },
          onDelete: () {
            setState(() => _actionsOpen = false);
            _deletePlan(plans.where((plan) => plan.isCreator).toList());
          },
        ),
      ),
    );
  }

  Future<Plan?> _pickPlan(
    List<Plan> plans,
    String title,
  ) => showModalBottomSheet<Plan>(
    context: context,
    backgroundColor: const Color(0xFF171717),
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.55,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE91E63),
                      child: Icon(Icons.folder_rounded, color: Colors.white),
                    ),
                    title: Text(
                      plan.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: plan.description.isEmpty
                        ? null
                        : Text(
                            plan.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                    onTap: () => Navigator.pop(sheetContext, plan),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _sharePlan(List<Plan> plans) async {
    final plan = await _pickPlan(plans, '¿Qué plan quieres compartir?');
    if (plan == null || !mounted) return;
    final description = plan.description.trim();
    final date = plan.meetingDate;
    final text = [
      'Plan: ${plan.title}',
      if (description.isNotEmpty) description,
      if (date != null)
        'Fecha: ${MaterialLocalizations.of(context).formatMediumDate(date)}',
    ].join('\n');
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: plan.title,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) _showMessage('No fue posible compartir el plan.');
    }
  }

  Future<void> _deletePlan(List<Plan> plans) async {
    final plan = await _pickPlan(plans, '¿Qué plan quieres eliminar?');
    if (plan == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: Text(
          '¿Deseas eliminar "${plan.title}" y sus eventos guardados? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(plansControllerProvider.notifier)
        .deletePlan(plan.id);
    if (!mounted) return;
    _showMessage(
      ok
          ? 'Plan "${plan.title}" eliminado.'
          : ref.read(plansControllerProvider).errorMessage ??
                'No fue posible eliminar el plan.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
