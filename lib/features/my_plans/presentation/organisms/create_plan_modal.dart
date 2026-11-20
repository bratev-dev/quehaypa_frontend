import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';

/// Modal de creación con la UX original intacta, pero persistiendo
/// en el backend: Page -> Controller -> UseCase -> Repository -> DataSource.
/// El back espera title (<=255), description opcional y meetingDate sin zona.
Future<int?> showCreatePlanModal(
  BuildContext context, {
  bool saveEvent = false,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  DateTime? pickedMeetingDate;
  var saving = false;

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      // Usamos un Padding dinámico que respeta el teclado sin bloquear la fluidez
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

      return Container(
        // Limitamos la altura máxima al 85% de la pantalla para que nunca tape los botones del sistema de forma abusiva
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        child: Form(
          key: formKey,
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

                // Campo Nombre
                TextFormField(
                  controller: nameController,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: 'Nombre del plan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    final v = value == null ? '' : value.trim();
                    if (v.isEmpty) return 'Campo obligatorio';
                    if (v.length > 255) return 'Máximo 255 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Descripción opcional
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Día de comienzo (Opcional)
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Día de comienzo (Opcional)',
                    hintText: 'Selecciona una fecha',
                    suffixIcon: const Icon(Icons.calendar_today_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (_) {
                    if (pickedMeetingDate != null &&
                        DateUtils.dateOnly(pickedMeetingDate!)
                            .isBefore(DateUtils.dateOnly(DateTime.now()))) {
                      return 'La fecha no puede ser anterior a hoy';
                    }
                    return null;
                  },
                  onTap: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: sheetContext,
                      initialDate: DateUtils.dateOnly(now),
                      firstDate: DateUtils.dateOnly(now),
                      lastDate: DateTime(now.year + 5, now.month, now.day),
                    );
                    if (pickedDate != null && sheetContext.mounted) {
                      final defaultTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        18,
                      );
                      pickedMeetingDate = defaultTime.isBefore(now)
                          ? now
                          : defaultTime;
                      dateController.text =
                          '${pickedDate.year.toString().padLeft(4, '0')}-'
                          '${pickedDate.month.toString().padLeft(2, '0')}-'
                          '${pickedDate.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Botón Guardar
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
                    onPressed: () async {
                      if (saving || !formKey.currentState!.validate()) return;
                      saving = true;

                      final container = ProviderScope.containerOf(
                        sheetContext,
                        listen: false,
                      );
                      final plan = await container
                          .read(plansControllerProvider.notifier)
                          .createPlanAndGet(
                            title: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            meetingDate: pickedMeetingDate,
                          );
                      saving = false;

                      if (!sheetContext.mounted) return;
                      if (plan != null) {
                        Navigator.pop(sheetContext, plan.id);
                      } else {
                        final msg =
                            container
                                .read(plansControllerProvider)
                                .errorMessage ??
                            'No fue posible crear el plan.';
                        ScaffoldMessenger.of(sheetContext)
                            .showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
                    child: Text(
                      saveEvent
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
                const SizedBox(height: 12), // Margen de seguridad inferior
              ],
            ),
          ),
        ),
      );
    },
  );
}
