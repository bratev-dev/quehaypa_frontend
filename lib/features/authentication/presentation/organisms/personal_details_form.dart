import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/app_snackbar.dart'; // <-- Importamos nuestro átomo de SnackBar
import '../atoms/custom_text_field.dart';
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

  late final FocusNode _dayFocusNode;
  late final FocusNode _monthFocusNode;
  late final FocusNode _yearFocusNode;

  @override
  void initState() {
    super.initState();
    _dayFocusNode = FocusNode();
    _monthFocusNode = FocusNode();
    _yearFocusNode = FocusNode();

    _dayFocusNode.addListener(
      () => _handleDateFieldBlur(_dayFocusNode, _dayFieldError),
    );
    _monthFocusNode.addListener(
      () => _handleDateFieldBlur(_monthFocusNode, _monthFieldError),
    );
    _yearFocusNode.addListener(
      () => _handleDateFieldBlur(_yearFocusNode, _yearFieldError),
    );
  }

  /// Al salir de un campo de fecha se avisa de inmediato si ese campo por sí
  /// solo ya es imposible (día 32, mes 13), sin esperar a los demás. Si el
  /// campo está bien y los tres ya tienen valor, se revisa la fecha completa
  /// (para casos como 31/02, que solo se detectan en conjunto).
  void _handleDateFieldBlur(FocusNode node, String? Function() fieldError) {
    if (node.hasFocus || !mounted) return;

    final error = fieldError() ?? _completeBirthDateError();

    if (error != null) {
      AppSnackbar.show(context, message: error, type: SnackbarType.info);
    }
  }

  String? _dayFieldError() =>
      _numberInRangeError(_dayController.text.trim(), 1, 31, 'día');

  String? _monthFieldError() =>
      _numberInRangeError(_monthController.text.trim(), 1, 12, 'mes');

  String? _yearFieldError() => _numberInRangeError(
    _yearController.text.trim(),
    1900,
    DateTime.now().year,
    'año',
  );

  /// Un campo vacío no reclama todavía: el usuario puede seguir llenando.
  String? _numberInRangeError(String value, int min, int max, String label) {
    if (value.isEmpty) return null;

    final parsed = int.tryParse(value);

    if (parsed == null) return 'El $label debe ser un número.';
    if (parsed < min || parsed > max) {
      return 'El $label debe estar entre $min y $max.';
    }

    return null;
  }

  /// Solo aplica cuando los tres campos ya tienen valor.
  String? _completeBirthDateError() {
    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (day.isEmpty || month.isEmpty || year.isEmpty) return null;

    return _birthDateError(day: day, month: month, year: year);
  }

  /// Devuelve el mensaje de error de la fecha, o null si es válida.
  String? _birthDateError({
    required String day,
    required String month,
    required String year,
  }) {
    // Primero los errores de cada campo por separado, para dar el mismo
    // mensaje puntual que ya se mostró al salir del campo.
    final fieldError =
        _dayFieldError() ?? _monthFieldError() ?? _yearFieldError();
    if (fieldError != null) return fieldError;

    final parsedDay = int.tryParse(day);
    final parsedMonth = int.tryParse(month);
    final parsedYear = int.tryParse(year);

    if (parsedDay == null || parsedMonth == null || parsedYear == null) {
      return 'La fecha de nacimiento debe contener solo números.';
    }

    // DateTime normaliza el desborde en vez de lanzar una excepción (ej.
    // DateTime(2024, 2, 31) se convierte en 3 de marzo), así que hay que
    // comparar los componentes para detectar fechas que no existen.
    final date = DateTime(parsedYear, parsedMonth, parsedDay);
    final isRealDate =
        date.year == parsedYear &&
        date.month == parsedMonth &&
        date.day == parsedDay;

    if (!isRealDate) {
      return 'La fecha de nacimiento no es válida.';
    }

    if (date.isAfter(DateTime.now())) {
      return 'La fecha de nacimiento no puede ser una fecha futura.';
    }

    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _idController.dispose();
    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();
    super.dispose();
  }

  Widget _buildInputPill({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    // El fondo de esta pantalla es azul, así que el borde en foco va amarillo.
    return CustomTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      keyboardType: keyboardType,
      focusedBorderColor: const Color(0xFFFFD600),
      hintColor: Colors.grey[400],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
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
                focusNode: _dayFocusNode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputPill(
                controller: _monthController,
                hintText: 'MM',
                keyboardType: TextInputType.number,
                focusNode: _monthFocusNode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputPill(
                controller: _yearController,
                hintText: 'AAAA',
                keyboardType: TextInputType.number,
                focusNode: _yearFocusNode,
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

            final birthDateError = _birthDateError(
              day: day,
              month: month,
              year: year,
            );

            if (birthDateError != null) {
              AppSnackbar.show(
                context,
                message: birthDateError,
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
