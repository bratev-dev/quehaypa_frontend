import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/dashboard_state.dart';
import '../molecules/event_card.dart';
import 'dashboard_header.dart';

class DashboardFeedView extends ConsumerStatefulWidget {
  const DashboardFeedView({super.key});

  @override
  ConsumerState<DashboardFeedView> createState() => _DashboardFeedViewState();
}

class _DashboardFeedViewState extends ConsumerState<DashboardFeedView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(dashboardControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: DashboardHeaderDelegate(
            topInset: MediaQuery.paddingOf(context).top,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        _content(state),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _content(DashboardState state) {
    if (state.status == DashboardStatus.initial ||
        state.status == DashboardStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.status == DashboardStatus.error) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                state.errorMessage ??
                    'No pudimos cargar los eventos. Inténtalo de nuevo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(dashboardControllerProvider.notifier).loadEvents(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.visibleEvents.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay eventos para tus intereses por ahora.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = state.visibleEvents[index];
        return EventCard(
          title: event.title,
          category: event.category,
          date: event.eventText,
        );
      }, childCount: state.visibleEvents.length),
    );
  }
}
