import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../profile_providers.dart';
import '../profile_colors.dart';
import 'edit_profile_page.dart';
import 'interests_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool loggingOut = false;

  Future<void> _logout() async {
    if (loggingOut) return;
    setState(() => loggingOut = true);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    final success = await ref
        .read(authenticationControllerProvider.notifier)
        .logout();
    container.invalidate(myProfileProvider);
    if (!success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Se eliminaron los datos de sesión del dispositivo. No se pudo confirmar el cierre remoto.',
          ),
        ),
      );
    }
    if (mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        backgroundColor: profileBackground,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            profile.when(
              data: (user) => _SettingsGroup(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: profileYellow,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    title: Text(
                      '${user.firstName} ${user.lastName}'.trim(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfilePage(user: user),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () =>
                  const LinearProgressIndicator(color: profileYellow),
              error: (_, _) => _SettingsGroup(
                children: [
                  ListTile(
                    title: const Text(
                      'No pudimos cargar tu perfil',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.refresh, color: Colors.white),
                    onTap: () => ref.invalidate(myProfileProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _GroupTitle('Cuenta'),
            _SettingsGroup(
              children: [
                _SettingsItem(
                  icon: Icons.edit_outlined,
                  title: 'Editar perfil',
                  onTap: profile.asData?.value == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                EditProfilePage(user: profile.asData!.value),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _GroupTitle('Preferencias'),
            _SettingsGroup(
              children: [
                _SettingsItem(
                  icon: Icons.interests_outlined,
                  title: 'Mis intereses',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InterestsPage(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _GroupTitle('Información y ayuda'),
            const _SettingsGroup(
              children: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Preguntas frecuentes',
                  subtitle: 'Próximamente',
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Términos del servicio',
                  subtitle: 'Próximamente',
                ),
                _SettingsItem(
                  icon: Icons.policy_outlined,
                  title: 'Política de usuario',
                  subtitle: 'Próximamente',
                ),
              ],
            ),
            const SizedBox(height: 34),
            FilledButton.icon(
              onPressed: loggingOut ? null : _logout,
              icon: loggingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: FilledButton.styleFrom(
                backgroundColor: profilePink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;
  const _GroupTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 0, 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF242426),
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: profileYellow),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, style: const TextStyle(color: Colors.white54)),
    trailing: onTap == null
        ? null
        : const Icon(Icons.chevron_right, color: Colors.white54),
    onTap: onTap,
  );
}
