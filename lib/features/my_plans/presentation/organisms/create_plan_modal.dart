import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';

/// Modal de creación con la UX original intacta, pero persistiendo
/// en el backend: Page -> Controller -> UseCase -> Repository -> DataSource.
/// El back espera title (<=255), description y meetingDate sin zona.
void showCreatePlanModal(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  DateTime? pickedMeetingDate;

  showModalBottomSheet(
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

                // Campo Descripción
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Campo obligatorio'
                      : null,
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
                  onTap: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: sheetContext,
                      initialDate: now,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      pickedMeetingDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        18,
                      );
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
                      if (!(formKey.currentState!.validate())) return;

                      final container = ProviderScope.containerOf(
                        sheetContext,
                        listen: false,
                      );
                      final ok = await container
                          .read(plansControllerProvider.notifier)
                          .createPlan(
                            title: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            meetingDate: pickedMeetingDate,
                          );

                      if (!sheetContext.mounted) return;
                      if (ok) {
                        Navigator.pop(sheetContext);
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
                    child: const Text(
                      'Guardar Plan',
                      style: TextStyle(
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
