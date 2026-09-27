import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../../core/errors/failtures.dart';
import '../../../authentication/presentation/controllers/register_providers.dart';
import '../profile_providers.dart';
import '../profile_colors.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  DateTime? birthDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.user.firstName);
    lastName = TextEditingController(text: widget.user.lastName);
    birthDate = widget.user.birthDate;
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await ref.read(updateProfileUseCaseProvider)(
        id: widget.user.id,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        birthDate: birthDate,
      );
      ref.invalidate(myProfileProvider);
      final refreshed = await ref
          .read(authenticationControllerProvider.notifier)
          .refreshProfileSession();
      if (mounted) {
        if (!refreshed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Datos guardados. No se pudo renovar la sesión; vuelve a iniciar sesión para actualizar sus datos.',
              ),
            ),
          );
        }
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is Failure
                  ? 'No se pudieron guardar los cambios: ${error.message}'
                  : 'No se pudieron guardar los cambios. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: profileBackground,
    appBar: AppBar(
      title: const Text('Editar perfil'),
      centerTitle: true,
      backgroundColor: profileBackground,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 54,
            backgroundColor: Color(0xFFE5E5E5),
            child: Icon(
              Icons.person_rounded,
              size: 65,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 30),
          Form(
            key: formKey,
            child: Material(
              color: const Color(0xFF242426),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _field('Nombre', firstName),
                    const SizedBox(height: 10),
                    _field('Apellido', lastName),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text(
                        'Fecha de nacimiento',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        birthDate == null
                            ? 'Sin registrar'
                            : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today_outlined,
                        color: profileYellow,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: birthDate ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => birthDate = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _readonly('Usuario', '@${widget.user.username}'),
          _readonly('Correo', widget.user.email),
          const SizedBox(height: 10),
          const Text(
            'El usuario y el correo no se pueden cambiar desde esta pantalla.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: profileYellow,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(54),
            ),
            child: Text(saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    ),
  );

  Widget _field(String label, TextEditingController controller) =>
      TextFormField(
        controller: controller,
        maxLength: 100,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF333336),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Escribe tu $label' : null,
      );

  Widget _readonly(String label, String value) => ListTile(
    title: Text(
      label,
      style: const TextStyle(color: Colors.white54, fontSize: 12),
    ),
    subtitle: Text(value, style: const TextStyle(color: Colors.white)),
  );
}
