import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/navigation/presentation/atoms/nav_icon_button.dart';
import 'package:frontend/features/organizer_dashboard/presentation/controllers/organizer_calendar_controller.dart';
import 'package:frontend/features/organizer_dashboard/presentation/controllers/organizer_calendar_state.dart';
import 'package:frontend/features/organizer_dashboard/presentation/molecules/organizer_event_card.dart';
import 'package:frontend/features/organizer_dashboard/presentation/molecules/organizer_event_skeleton.dart';
import 'package:frontend/features/organizer_dashboard/presentation/organisms/organizer_calendar_header.dart';
import 'package:frontend/features/organizer_dashboard/presentation/organisms/organizer_calendar_map.dart';
import 'package:frontend/features/organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

void main() {
  testWidgets('la agenda muestra eventos, skeletons y una fecha vacía', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: OrganizerCalendarMap())),
      ),
    );

    expect(find.byType(OrganizerEventCard), findsNWidgets(3));
    expect(find.text('Congreso Gastronómico'), findsOneWidget);
    final scrollViews = find.byType(SingleChildScrollView);
    expect(scrollViews, findsNWidgets(2));
    final hourTop = tester.getTopLeft(find.text('07:00')).dy;
    final hourLeft = tester.getTopLeft(find.text('07:00')).dx;
    await tester.drag(scrollViews.last, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('07:00')).dy, hourTop);
    await tester.drag(scrollViews.first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('07:00')).dx, lessThan(hourLeft));

    final selection = container
        .read(organizerCalendarProvider.notifier)
        .selectDate(DateTime(2026, 6, 2));
    await tester.pump();
    expect(find.byType(OrganizerEventCard), findsNothing);
    expect(find.byType(OrganizerEventSkeleton), findsNWidgets(2));

    await tester.pump(const Duration(milliseconds: 450));
    await selection;
    await tester.pump();
    expect(find.byType(OrganizerEventSkeleton), findsNothing);
    expect(find.byType(OrganizerEventCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el selector cambia fecha y período y reinicia su scroll', (
    tester,
  ) async {
    final container = ProviderContainer();
    final scrollController = ScrollController();
    addTearDown(() {
      scrollController.dispose();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: OrganizerCalendarHeader(
                  dateScrollController: scrollController,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('2'));
    await tester.pump();
    expect(container.read(organizerCalendarProvider).selectedDate.day, 2);
    await tester.pump(const Duration(milliseconds: 450));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(0));

    await tester.tap(find.text('mes'));
    await tester.pump();
    expect(
      container.read(organizerCalendarProvider).period,
      CalendarPeriod.month,
    );
    expect(scrollController.offset, 0);
    expect(find.text('jun'), findsOneWidget);

    await tester.tap(find.text('año'));
    await tester.pump();
    expect(
      container.read(organizerCalendarProvider).period,
      CalendarPeriod.year,
    );
    await tester.tap(find.text('2027'));
    await tester.pump();
    expect(container.read(organizerCalendarProvider).selectedDate.year, 2027);
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la vista previa usa cinco botones y cambia de sección', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 822);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OrganizerDashboardPage(preview: true)),
      ),
    );

    expect(find.byType(OrganizerCalendarHeader), findsOneWidget);
    expect(find.byType(OrganizerCalendarMap), findsOneWidget);
    expect(find.byType(NavIconButton), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.byType(OrganizerCalendarMap), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
