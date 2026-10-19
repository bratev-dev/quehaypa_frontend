import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/presentation/organisms/custom_bottom_nav.dart';
import '../../../navigation/presentation/organisms/sliding_navigation_stack.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../../my_plans/presentation/pages/my_plans_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../atoms/calendar_selection_notch.dart';
import '../controllers/organizer_calendar_controller.dart';
import '../controllers/organizer_calendar_state.dart';
import '../molecules/calendar_date_strip.dart';
import '../organisms/organizer_calendar_header.dart';
import '../organisms/organizer_calendar_map.dart';

class OrganizerDashboardTemplate extends ConsumerWidget {
  const OrganizerDashboardTemplate({super.key, this.preview = false});

  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final screens = <Widget>[
      const _OrganizerCalendarHome(),
      const _PrototypeSection(label: 'Mapa'),
      const _PrototypeSection(label: 'Eventos'),
      if (preview)
        const _PrototypeSection(label: 'Planes')
      else
        const MyPlansPage(),
      if (preview)
        const _PrototypeSection(label: 'Perfil')
      else
        const ProfilePage(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          SlidingNavigationStack(index: index.clamp(0, 4), children: screens),
          const CustomBottomNav(organizer: true),
        ],
      ),
    );
  }
}

class _OrganizerCalendarHome extends ConsumerStatefulWidget {
  const _OrganizerCalendarHome();

  @override
  ConsumerState<_OrganizerCalendarHome> createState() =>
      _OrganizerCalendarHomeState();
}

class _OrganizerCalendarHomeState
    extends ConsumerState<_OrganizerCalendarHome> {
  final ScrollController _dateScrollController = ScrollController();

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  double _selectedDateCenter(double index, double width) {
    final scrollOffset = _dateScrollController.hasClients
        ? _dateScrollController.offset
        : 0.0;
    return (77 + index * 54 - scrollOffset)
        .clamp(
          CalendarSelectionNotch.width / 2,
          width - CalendarSelectionNotch.width / 2,
        )
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerCalendarProvider);
    final selectedIndex = switch (state.period) {
      CalendarPeriod.day => state.selectedDate.weekday - 1,
      CalendarPeriod.month || CalendarPeriod.year => 2,
    };
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
            child: OrganizerCalendarHeader(
              dateScrollController: _dateScrollController,
            ),
          ),
          SizedBox(
            height: CalendarSelectionNotch.height,
            child: LayoutBuilder(
              builder: (context, constraints) => TweenAnimationBuilder<double>(
                tween: Tween<double>(end: selectedIndex.toDouble()),
                duration: CalendarDateStrip.selectionDuration,
                curve: CalendarDateStrip.selectionCurve,
                builder: (context, animatedIndex, child) => AnimatedBuilder(
                  animation: _dateScrollController,
                  builder: (context, child) => Stack(
                    children: [
                      Positioned(
                        left:
                            _selectedDateCenter(
                              animatedIndex,
                              constraints.maxWidth,
                            ) -
                            CalendarSelectionNotch.width / 2,
                        top: 0,
                        child: child!,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const CalendarSelectionNotch(),
              ),
            ),
          ),
          const Expanded(child: OrganizerCalendarMap()),
        ],
      ),
    );
  }
}

class _PrototypeSection extends StatelessWidget {
  const _PrototypeSection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 24),
    ),
  );
}
