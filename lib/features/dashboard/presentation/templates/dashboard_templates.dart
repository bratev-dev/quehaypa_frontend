import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/presentation/organisms/custom_bottom_nav.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../organisms/dashboard_header.dart';
import '../molecules/event_card.dart';

class DashboardTemplate extends ConsumerWidget {
  const DashboardTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const _HomeFeedView(),
      const Center(
        child: Text(
          'Vista de Mapa 🗺️',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      const Center(
        child: Text(
          'Vista de Mis Planes 📅',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      const Center(
        child: Text(
          'Vista de Mi Perfil 👤',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          IndexedStack(index: currentIndex, children: screens),
          const CustomBottomNav(),
        ],
      ),
    );
  }
}

class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header persistente y anclado nativamente que maneja la animación del arco y del logo
        const SliverPersistentHeader(
          pinned: true,
          delegate: DashboardHeaderDelegate(),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return EventCard(
              title: 'Evento Cultural en Popayán #${index + 1}',
              category: index.isEven ? 'Tecnología' : 'Música',
              date: '15 Oct - 8:00 PM',
            );
          }, childCount: 6),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
