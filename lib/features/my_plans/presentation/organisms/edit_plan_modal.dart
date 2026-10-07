import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/domain/entities/plan.dart';
import '../../../plans/presentation/controllers/plans_controller.dart';

Future<bool?> showEditPlanModal(BuildContext context, Plan plan) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => EditPlanModal(plan: plan),
  );
}

class EditPlanModal extends ConsumerStatefulWidget {
  final Plan plan;

  const EditPlanModal({super.key, required this.plan});

  @override
  ConsumerState<EditPlanModal> createState() => _EditPlanModalState();
}

class _EditPlanModalState extends ConsumerState<EditPlanModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  DateTime? _meetingDate;
  bool _dateChanged = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan.title);
    _descriptionController = TextEditingController(
      text: widget.plan.description,
    );
    _meetingDate = widget.plan.meetingDate;
    _dateController = TextEditingController(text: _formatDate(_meetingDate));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    if (_saving) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = DateTime(today.year + 5, today.month, today.day);
    final current = _meetingDate;
    final initialDate = current == null || current.isBefore(today)
        ? today
        : current.isAfter(lastDate)
        ? lastDate
        : DateUtils.dateOnly(current);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    final now = DateTime.now();
    final defaultTime = DateTime(picked.year, picked.month, picked.day, 18);
    setState(() {
      _meetingDate = defaultTime.isBefore(now) ? now : defaultTime;
      _dateChanged = true;
      _dateController.text = _formatDate(_meetingDate);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final ok = await ref
        .read(plansControllerProvider.notifier)
        .updatePlan(
          planId: widget.plan.id,
          title: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          meetingDate: _meetingDate,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _errorMessage =
          ref.read(plansControllerProvider).errorMessage ??
          'No fue posible actualizar el plan.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_saving,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  maxLength: 255,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Nombre del plan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final title = value?.trim() ?? '';
                    if (title.isEmpty) return 'Campo obligatorio';
                    if (title.length > 255) return 'Máximo 255 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  enabled: !_saving,
                  onTap: _pickDate,
                  validator: (_) {
                    if (_dateChanged &&
                        _meetingDate != null &&
                        DateUtils.dateOnly(_meetingDate!)
                            .isBefore(DateUtils.dateOnly(DateTime.now()))) {
                      return 'La fecha no puede ser anterior a hoy';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Día de comienzo (opcional)',
                    hintText: 'Selecciona una fecha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _meetingDate == null
                        ? const Icon(Icons.calendar_today_rounded)
                        : IconButton(
                            tooltip: 'Quitar fecha',
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                    _meetingDate = null;
                                    _dateChanged = true;
                                    _dateController.clear();
                                  }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar cambios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
