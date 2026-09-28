import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_plans/presentation/pages/my_plans_page.dart';
import '../../../navigation/presentation/organisms/custom_bottom_nav.dart';
import '../../../navigation/presentation/organisms/sliding_navigation_stack.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../organisms/dashboard_feed_view.dart';

class DashboardTemplate extends ConsumerWidget {
  const DashboardTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const DashboardFeedView(), // Índice 0: Feed principal con tu header intacto
      const Center(
        child: Text(
          'Vista de Mapa 🗺️',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ), // Índice 1: Mapa
      const MyPlansPage(), // Índice 2: Mis Planes (UI Spotify + backend real)
      const ProfilePage(), // Índice 3: Perfil
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          SlidingNavigationStack(index: currentIndex, children: screens),
          const CustomBottomNav(),
        ],
      ),
    );
  }
}
