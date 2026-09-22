import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../controllers/plans_controller.dart';
import '../controllers/plans_state.dart';

/// Pantalla de verificación CRUD QHP-78: lista /my-plans, crear, editar,
/// eliminar. Sigue Page -> Controller -> UseCase -> Repository -> DataSource.
class MyPlansPage extends ConsumerStatefulWidget {
  const MyPlansPage({super.key});

  @override
  ConsumerState<MyPlansPage> createState() => _MyPlansPageState();
}

class _MyPlansPageState extends ConsumerState<MyPlansPage> {
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Mis Planes'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(context),
        child: const Icon(Icons.add),
      ),
      body: switch (state.status) {
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
                onPressed: () =>
                    ref.read(plansControllerProvider.notifier).loadMyPlans(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        _ =>
          state.plans.isEmpty
              ? const Center(
                  child: Text(
                    'Aún no tienes planes. Crea el primero.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(plansControllerProvider.notifier).loadMyPlans(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: state.plans.length,
                    itemBuilder: (context, index) {
                      final plan = state.plans[index];
                      return Dismissible(
                        key: ValueKey(plan.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => ref
                            .read(plansControllerProvider.notifier)
                            .deletePlan(plan.id),
                        child: ListTile(
                          title: Text(
                            plan.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            plan.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: plan.isCreator
                              ? const Icon(Icons.edit, color: Colors.white54)
                              : null,
                          onTap: plan.isCreator
                              ? () => _showPlanDialog(context, plan: plan)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      },
    );
  }

  Future<void> _showPlanDialog(BuildContext context, {Plan? plan}) async {
    final titleController = TextEditingController(text: plan?.title ?? '');
    final descController = TextEditingController(text: plan?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan == null ? 'Crear plan' : 'Editar plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título *'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final title = titleController.text.trim();
    if (title.isEmpty || title.length > 255) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El título es obligatorio y máximo 255 caracteres.'),
          ),
        );
      }
      return;
    }

    final notifier = ref.read(plansControllerProvider.notifier);
    if (plan == null) {
      await notifier.createPlan(
        title: title,
        description: descController.text.trim(),
      );
    } else {
      await notifier.updatePlan(
        planId: plan.id,
        title: title,
        description: descController.text.trim(),
        meetingDate: plan.meetingDate,
      );
    }
  }
}
