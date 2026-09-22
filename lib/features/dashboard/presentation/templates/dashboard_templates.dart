import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../my_plans/presentation/pages/my_plans_page.dart';
import '../../../navigation/presentation/organisms/custom_bottom_nav.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../controllers/dashboard_controller.dart';
import '../organisms/dashboard_header.dart';
import '../molecules/event_card.dart';

class DashboardTemplate extends ConsumerWidget {
  const DashboardTemplate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    final List<Widget> screens = [
      const _HomeFeedView(), // Índice 0: Feed principal con tu header intacto
      const Center(
        child: Text(
          'Vista de Mapa 🗺️',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ), // Índice 1: Mapa
      const MyPlansPage(), // Índice 2: Mis Planes (UI Spotify + backend real)
      const Center(
        child: Text(
          'Vista de Mi Perfil 👤',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ), // Índice 3: Perfil
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

class _HomeFeedView extends ConsumerWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleEvents = ref.watch(
      dashboardControllerProvider.select((s) => s.visibleEvents),
    );

    return CustomScrollView(
      slivers: [
        // Tu header persistente intacto con su delegate original
        SliverPersistentHeader(
          pinned: true,
          delegate: DashboardHeaderDelegate(
            topInset: MediaQuery.paddingOf(context).top,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        if (visibleEvents.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No hay eventos para tus intereses por ahora.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final event = visibleEvents[index];
              return EventCard(
                title: event.title,
                category: event.category,
                date: event.date,
              );
            }, childCount: visibleEvents.length),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
