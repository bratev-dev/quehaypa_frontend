import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../atoms/app_snackbar.dart'; // <-- Importamos el átomo global
import '../atoms/primary_button.dart';
import '../controllers/register_controller.dart';
import '../controllers/register_state.dart';
import '../molecules/role_card.dart';

class RoleSelectionForm extends ConsumerStatefulWidget {
  const RoleSelectionForm({super.key});

  @override
  ConsumerState<RoleSelectionForm> createState() => _RoleSelectionFormState();
}

class _RoleSelectionFormState extends ConsumerState<RoleSelectionForm> {
  UserRole? _tempSelectedRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleCard(
          title: 'Usuario',
          widthFactor: 0.65,
          isSelected: _tempSelectedRole == UserRole.user,
          onTap: () {
            setState(() {
              _tempSelectedRole = UserRole.user;
            });
          },
        ),
        const SizedBox(height: 16),
        RoleCard(
          title: 'Organizador',
          widthFactor: 1.0, // Ancho completo
          isSelected: _tempSelectedRole == UserRole.organizer,
          onTap: () {
            setState(() {
              _tempSelectedRole = UserRole.organizer;
            });
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text: 'Continuar',
            backgroundColor: const Color(0xFFFFD600),
            textColor: Colors.black,
            onPressed: () {
              if (_tempSelectedRole == null) {
                AppSnackbar.show(
                  context,
                  'Por favor selecciona un rol para continuar.',
                );
                return;
              }
              ref
                  .read(registerControllerProvider.notifier)
                  .selectRole(_tempSelectedRole!);
            },
          ),
        ),
      ],
    );
  }
}
