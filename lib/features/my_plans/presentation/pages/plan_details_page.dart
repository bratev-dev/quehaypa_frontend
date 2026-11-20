import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failtures.dart';
import '../../../../core/widgets/top_status_snackbar.dart';
import '../../../plans/domain/entities/plan.dart';
import '../../../plans/presentation/controllers/plans_controller.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../molecules/saved_plan_event_card_molecule.dart';
import '../organisms/edit_plan_modal.dart';

/// Vista de consulta de los eventos guardados en un plan.
class PlanDetailsPage extends ConsumerStatefulWidget {
  final Plan plan;

  const PlanDetailsPage({super.key, required this.plan});

  @override
  ConsumerState<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends ConsumerState<PlanDetailsPage>
    with SingleTickerProviderStateMixin {
  List<EventSeed>? _events;
  String? _error;
  int? _removingEventId;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _events = null;
      _error = null;
    });
    try {
      final events = await ref
          .read(plansControllerProvider.notifier)
          .loadPlanEvents(widget.plan.id);
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos cargar los eventos del plan.');
      }
    }
  }

  Future<void> _removeEvent(EventSeed event) async {
    if (_removingEventId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar evento?'),
        content: Text(
          '¿Deseas quitar "${event.title}" de este plan? El evento seguirá disponible para volver a guardarlo.',
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
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removingEventId = event.id);
    try {
      await ref
          .read(plansControllerProvider.notifier)
          .removePlanEvent(widget.plan.id, event.id);
      if (!mounted) return;
      setState(() {
        _events = _events?.where((item) => item.id != event.id).toList();
      });
      _showMessage('Evento quitado del plan.', success: true);
    } on Failure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('No fue posible quitar el evento.');
    } finally {
      if (mounted) setState(() => _removingEventId = null);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    TopStatusSnackbar.show(context, message: message, success: success);
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansControllerProvider).plans;
    final plan =
        plans.where((item) => item.id == widget.plan.id).firstOrNull ??
        widget.plan;
    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD600),
        foregroundColor: Colors.black,
        title: const Text('Mi plan'),
        actions: [
          if (plan.isCreator)
            TextButton.icon(
              onPressed: () async {
                final saved = await showEditPlanModal(context, plan);
                if (saved == true && mounted) {
                  _showMessage('Plan actualizado.', success: true);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description, style: const TextStyle(fontSize: 15)),
            ],
            if (plan.meetingDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Fecha: ${MaterialLocalizations.of(context).formatMediumDate(plan.meetingDate!)}',
                style: const TextStyle(fontSize: 15),
              ),
            ],
            const SizedBox(height: 28),
            const Text(
              'Eventos guardados',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              _StatusCard(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                buttonLabel: 'Reintentar',
                onPressed: _load,
              )
            else if (_events == null)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      height: 96,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white54,
                          Colors.white,
                          _pulse.value,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              )
            else if (_events!.isEmpty)
              const _StatusCard(
                icon: Icons.event_available_outlined,
                message: 'Todavía no hay eventos en este plan. Explora y guarda uno.',
              )
            else
              ..._events!.map(
                (event) => SavedPlanEventCardMolecule(
                  event: event,
                  canRemove: plan.isCreator,
                  isRemoving: _removingEventId == event.id,
                  onRemove: () => _removeEvent(event),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _StatusCard({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: const Color(0xFFE91E63)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (buttonLabel != null && onPressed != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onPressed, child: Text(buttonLabel!)),
        ],
      ],
    ),
  );
}
