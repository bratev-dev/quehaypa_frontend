import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';

Future<int?> showCreatePlanModal(
  BuildContext context, {
  bool saveEvent = false,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _CreatePlanForm(saveEvent: saveEvent),
);

class _CreatePlanForm extends ConsumerStatefulWidget {
  const _CreatePlanForm({required this.saveEvent});

  final bool saveEvent;

  @override
  ConsumerState<_CreatePlanForm> createState() => _CreatePlanFormState();
}

class _CreatePlanFormState extends ConsumerState<_CreatePlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _date = TextEditingController();
  DateTime? _meetingDate;
  bool _saving = false;

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _date.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Campo obligatorio';
    if (name.length > 255) return 'Máximo 255 caracteres';
    return null;
  }

  String? _validateDate(String? _) {
    final date = _meetingDate;
    if (date != null &&
        DateUtils.dateOnly(date).isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return 'La fecha no puede ser anterior a hoy';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (!mounted || picked == null) return;

    final defaultTime = DateTime(picked.year, picked.month, picked.day, 18);
    _meetingDate = defaultTime.isBefore(now) ? now : defaultTime;
    _date.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final plan = await ref
        .read(plansControllerProvider.notifier)
        .createPlanAndGet(
          title: _name.text.trim(),
          description: _description.text.trim(),
          meetingDate: _meetingDate,
        );
    if (!mounted) return;
    if (plan != null) {
      Navigator.pop(context, plan.id);
      return;
    }

    setState(() => _saving = false);
    final message =
        ref.read(plansControllerProvider).errorMessage ??
        'No fue posible crear el plan.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
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
                'Crear Nuevo Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plan',
                  border: _fieldBorder,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: _fieldBorder,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _date,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Día de comienzo (Opcional)',
                  hintText: 'Selecciona una fecha',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                  border: _fieldBorder,
                ),
                validator: _validateDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(
                    widget.saveEvent
                        ? 'Crear plan y guardar evento'
                        : 'Guardar Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
