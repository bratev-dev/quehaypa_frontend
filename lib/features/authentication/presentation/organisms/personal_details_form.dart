import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/app_snackbar.dart'; // <-- Importamos nuestro átomo de SnackBar
import '../atoms/primary_button.dart';
import '../controllers/register_controller.dart';
import '../controllers/register_state.dart';

class PersonalDetailsForm extends ConsumerStatefulWidget {
  const PersonalDetailsForm({super.key});

  @override
  ConsumerState<PersonalDetailsForm> createState() =>
      _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends ConsumerState<PersonalDetailsForm> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Widget _buildInputPill({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final isOrganizer = registerState.selectedRole == UserRole.organizer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fila 1: Nombre y Apellido
        Row(
          children: [
            Expanded(
              child: _buildInputPill(
                controller: _nameController,
                hintText: 'Nombre',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputPill(
                controller: _lastNameController,
                hintText: 'Apellido',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Fila 2: Nombre de usuario
        _buildInputPill(
          controller: _usernameController,
          hintText: 'Nombre de usuario',
        ),
        const SizedBox(height: 14),

        // Fila 3: Fecha de nacimiento (DD / MM / YY)
        Row(
          children: [
            Expanded(
              child: _buildInputPill(
                controller: _dayController,
                hintText: 'DD',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputPill(
                controller: _monthController,
                hintText: 'MM',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputPill(
                controller: _yearController,
                hintText: 'YY',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        // Fila 4: CC (SOLO se muestra si es Organizador)
        if (isOrganizer) ...[
          const SizedBox(height: 14),
          _buildInputPill(
            controller: _idController,
            hintText: 'CC',
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 28),

        // Botón de continuar
        PrimaryButton(
          text: 'Continuar',
          backgroundColor: const Color(0xFF0038FF),
          textColor: Colors.white,
          onPressed: () {
            final name = _nameController.text.trim();
            final lastName = _lastNameController.text.trim();
            final username = _usernameController.text.trim();
            final day = _dayController.text.trim();
            final month = _monthController.text.trim();
            final year = _yearController.text.trim();
            final cc = isOrganizer ? _idController.text.trim() : null;

            // Validaciones con el AppSnackbar
            if (name.isEmpty ||
                lastName.isEmpty ||
                username.isEmpty ||
                day.isEmpty ||
                month.isEmpty ||
                year.isEmpty) {
              AppSnackbar.show(
                context,
                message: 'Por favor completa todos los campos.',
                type: SnackbarType.info,
              );
              return;
            }

            if (isOrganizer && (cc == null || cc.isEmpty)) {
              AppSnackbar.show(
                context,
                message: 'Por favor ingresa tu número de cédula.',
                type: SnackbarType.info,
              );
              return;
            }

            final parsedDay = int.tryParse(day);
            final parsedMonth = int.tryParse(month);
            final parsedYear = int.tryParse(year);

            if (parsedDay == null ||
                parsedMonth == null ||
                parsedYear == null) {
              AppSnackbar.show(
                context,
                message: 'La fecha de nacimiento debe contener solo números.',
                type: SnackbarType.info,
              );
              return;
            }

            // DateTime normaliza el desborde en vez de lanzar una excepción
            // (ej. DateTime(2024, 2, 31) se convierte en 3 de marzo), así
            // que hay que comparar los componentes para detectar fechas
            // que en realidad no existen.
            final constructedDate = DateTime(
              parsedYear,
              parsedMonth,
              parsedDay,
            );
            final isRealDate =
                constructedDate.year == parsedYear &&
                constructedDate.month == parsedMonth &&
                constructedDate.day == parsedDay;

            if (!isRealDate) {
              AppSnackbar.show(
                context,
                message: 'La fecha de nacimiento no es válida.',
                type: SnackbarType.info,
              );
              return;
            }

            if (constructedDate.isAfter(DateTime.now())) {
              AppSnackbar.show(
                context,
                message:
                    'La fecha de nacimiento no puede ser una fecha futura.',
                type: SnackbarType.info,
              );
              return;
            }

            final birthDate = '$day/$month/$year';

            ref
                .read(registerControllerProvider.notifier)
                .savePersonalDetails(
                  name: name,
                  lastname: lastName,
                  username: username,
                  birthDate: birthDate,
                  cc: cc,
                );
          },
        ),
      ],
    );
  }
}
