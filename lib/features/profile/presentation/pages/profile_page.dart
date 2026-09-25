import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/domain/entities/user.dart';
import '../molecules/profile_info_row.dart';
import '../organisms/profile_section_panel.dart';
import '../profile_colors.dart';
import '../profile_providers.dart';
import 'settings_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int section = 2;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    return ColoredBox(
      color: profileBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mi perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configuración',
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            profile.when(
              loading: () => const SizedBox(
                height: 205,
                child: Center(
                  child: CircularProgressIndicator(color: profileYellow),
                ),
              ),
              error: (_, _) => SizedBox(
                height: 205,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No pudimos cargar tu perfil.',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(myProfileProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (user) => _ProfileHeader(user: user),
            ),
            Expanded(
              child: ProfileSectionPanel(
                section: section,
                onSectionSelected: (value) => setState(() => section = value),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(section),
                    child: section == 2
                        ? _ProfileDetails(user: profile.asData?.value)
                        : _EmptySection(
                            icon: section == 0
                                ? Icons.favorite_border_rounded
                                : Icons.people_outline_rounded,
                            title: section == 0
                                ? 'Tus favoritos'
                                : 'Tus amigos',
                            message: section == 0
                                ? 'Aquí aparecerá lo que guardes como favorito.'
                                : 'La lista de amigos estará disponible próximamente.',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = '${user.firstName} ${user.lastName}'.trim();
    final picture = user.profilePictureUrl;
    return SizedBox(
      height: 205,
      child: Column(
        children: [
          CircleAvatar(
            radius: 66,
            backgroundColor: const Color(0xFFE5E5E5),
            backgroundImage: picture != null && picture.isNotEmpty
                ? NetworkImage(picture)
                : null,
            child: picture == null || picture.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 72,
                    color: Color(0xFF777777),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? user.username : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${user.username}',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  final User? user;
  const _ProfileDetails({this.user});

  @override
  Widget build(BuildContext context) {
    final bottomClearance = 150 + MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(28, 24, 28, bottomClearance),
      children: [
        const Text(
          'Tu información',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Edita tus datos e intereses desde Configuración.',
          style: TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: 18),
        ProfileInfoRow(
          label: 'Nombre',
          value: user == null
              ? '—'
              : '${user!.firstName} ${user!.lastName}'.trim(),
        ),
        ProfileInfoRow(
          label: 'Usuario',
          value: user == null ? '—' : '@${user!.username}',
        ),
        ProfileInfoRow(label: 'Correo', value: user?.email ?? '—'),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: profileBlue),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
