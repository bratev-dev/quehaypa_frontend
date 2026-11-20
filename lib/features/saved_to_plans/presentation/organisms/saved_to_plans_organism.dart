import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_plans/presentation/organisms/create_plan_modal.dart';
import '../../../plans/presentation/controllers/plans_controller.dart';
import '../../../plans/presentation/controllers/plans_state.dart';
import '../../../plans/presentation/controllers/plans_providers.dart';
import '../../../../core/errors/failtures.dart';
import '../../../../core/widgets/top_status_snackbar.dart';
import '../molecules/save_header_molecule.dart';
import '../molecules/save_to_plan_row_molecule.dart';
import '../atoms/search_input_atom.dart';

/// Hoja de Figma «Guardado en», conectada con los eventos persistidos del plan.
class SavedToPlansOrganism extends ConsumerStatefulWidget {
  final int eventId;
  final String eventTitle;

  const SavedToPlansOrganism({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<SavedToPlansOrganism> createState() =>
      _SavedToPlansOrganismState();
}

class _SavedToPlansOrganismState extends ConsumerState<SavedToPlansOrganism>
    with SingleTickerProviderStateMixin {
  final Set<int> _savedPlanIds = {};
  final Set<int> _savingPlanIds = {};
  final _search = TextEditingController();
  String? _associationError;
  bool _loadingAssociations = true;
  late final AnimationController _skeletonPulse;

  @override
  void initState() {
    super.initState();
    _skeletonPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _skeletonPulse.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loadingAssociations = true;
      _associationError = null;
    });
    await ref.read(plansControllerProvider.notifier).loadMyPlans();
    if (!mounted) return;
    final plans = ref.read(plansControllerProvider);
    if (plans.status == PlansStatus.error) {
      setState(() => _loadingAssociations = false);
      return;
    }
    try {
      final getEvents = ref.read(getPlanEventsUseCaseProvider);
      final owned = plans.plans.where((plan) => plan.isCreator).toList();
      final results = await Future.wait(
        owned.map(
          (plan) async => (
            plan.id,
            (await getEvents(plan.id))
                .any((event) => event.id == widget.eventId),
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _savedPlanIds
          ..clear()
          ..addAll(
            results.where((result) => result.$2).map((result) => result.$1),
          );
        _loadingAssociations = false;
      });
    } on Failure catch (error) {
      if (mounted) {
        setState(() {
          _associationError = error.message;
          _loadingAssociations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _associationError = 'No pudimos consultar tus eventos guardados.';
          _loadingAssociations = false;
        });
      }
    }
  }

  Future<void> _addToPlan(int planId) async {
    final planTitle = ref
        .read(plansControllerProvider)
        .plans
        .where((plan) => plan.id == planId)
        .map((plan) => plan.title)
        .firstOrNull;
    if (_savedPlanIds.contains(planId)) {
      _showMessage('Este evento ya está guardado en ese plan.');
      return;
    }
    if (_savingPlanIds.contains(planId)) return;
    setState(() => _savingPlanIds.add(planId));
    try {
      await ref.read(addPlanEventUseCaseProvider)(planId, widget.eventId);
      if (!mounted) return;
      setState(() => _savedPlanIds.add(planId));
      _showMessage(
        planTitle == null
            ? 'Evento guardado en el plan.'
            : 'Evento guardado en "$planTitle".',
        success: true,
      );
    } on ConflictFailure catch (error) {
      if (!mounted) return;
      setState(() => _savedPlanIds.add(planId));
      _showMessage(error.message);
    } on Failure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('No pudimos guardar el evento. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _savingPlanIds.remove(planId));
    }
  }

  Future<void> _createPlanAndSave() async {
    final planId = await showCreatePlanModal(context, saveEvent: true);
    if (!mounted || planId == null) return;
    _search.clear();
    await _addToPlan(planId);
  }

  void _showMessage(String message, {bool success = false}) {
    TopStatusSnackbar.show(context, message: message, success: success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plansControllerProvider);
    final searchQuery = _search.text.toLowerCase();

    final filteredPlans = state.plans
        .where((plan) => plan.isCreator)
        .where((plan) => plan.title.toLowerCase().contains(searchQuery))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SaveHeaderMolecule(onCreatePlan: _createPlanAndSave),
        const SizedBox(height: 4),
        Text(
          'Evento: ${widget.eventTitle}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 16),
        SearchInputAtom(controller: _search, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        Expanded(
          child: switch (state.status) {
            PlansStatus.initial ||
            PlansStatus.loading when state.plans.isEmpty => _skeleton(),
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
                    onPressed: _load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            _ when _loadingAssociations => _skeleton(),
            _ when _associationError != null => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Colors.white70,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _associationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            ),
            _ when filteredPlans.isEmpty => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_open_rounded,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    searchQuery.isEmpty
                        ? 'Aún no tienes planes propios.'
                        : 'No encontramos planes con ese nombre.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (searchQuery.isEmpty)
                    TextButton(
                      onPressed: _createPlanAndSave,
                      child: const Text('Crear mi primer plan'),
                    ),
                ],
              ),
            ),
            _ => ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredPlans.length,
              itemBuilder: (context, index) {
                final plan = filteredPlans[index];
                final isSelected = _savedPlanIds.contains(plan.id);
                return SaveToPlanRowMolecule(
                  planName: plan.title,
                  details: plan.description.isEmpty
                      ? 'Plan #${plan.id}'
                      : plan.description,
                  isSelected: isSelected,
                  isSaving: _savingPlanIds.contains(plan.id),
                  onToggle: () => _addToPlan(plan.id),
                );
              },
            ),
          },
        ),
      ],
    );
  }

  Widget _skeleton() => AnimatedBuilder(
    animation: _skeletonPulse,
    builder: (context, _) => ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF2B2B2B),
            const Color(0xFF484848),
            _skeletonPulse.value,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 20),
            const CircleAvatar(radius: 18, backgroundColor: Colors.white24),
          ],
        ),
      ),
    ),
  );
}
