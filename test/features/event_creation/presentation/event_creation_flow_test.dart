import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/animations/button_reveal_page_route.dart';
import 'package:frontend/features/event_creation/domain/created_event_preview.dart';
import 'package:frontend/features/event_creation/presentation/atoms/event_creation_notch.dart';
import 'package:frontend/features/event_creation/presentation/controllers/event_creation_controller.dart';
import 'package:frontend/features/event_creation/presentation/event_creation_colors.dart';
import 'package:frontend/features/event_creation/presentation/molecules/event_link_preview.dart';
import 'package:frontend/features/event_creation/presentation/pages/event_creation_page.dart';
import 'package:frontend/features/event_creation/presentation/templates/event_creation_template.dart';
import 'package:frontend/features/organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('el botón del dashboard abre y cierra Crear Evento', (
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
    await tester.tap(find.text('Crear Evento'));
    await tester.pumpAndSettle();
    final eventRoute = ModalRoute.of(
      tester.element(find.byType(EventCreationPage)),
    );
    expect(eventRoute, isA<ButtonRevealPageRoute<CreatedEventPreview>>());
    expect(find.byType(EventCreationPage), findsOneWidget);
    expect(find.byType(EventCreationNotch), findsOneWidget);
    expect(find.text('¡Empecemos!'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar crear evento'));
    await tester.pumpAndSettle();
    expect(find.byType(EventCreationPage), findsNothing);
    expect(find.byType(OrganizerDashboardPage), findsOneWidget);
  });

  testWidgets('el Stepper conserva datos, acepta archivos y muestra enlaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 822);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const business = EventBusiness(id: 'business-1', name: 'Mi negocio');
    final controller = EventCreationController(
      now: () => DateTime(2026, 6, 1),
      businesses: const [business],
    );
    final linkController = TextEditingController();
    addTearDown(() {
      controller.dispose();
      linkController.dispose();
    });
    controller.updateName('Concierto');
    controller.updateCategory('Música');
    controller.updateStartTime(const TimeOfDay(hour: 22, minute: 0));
    controller.updateEndTime(const TimeOfDay(hour: 4, minute: 0));
    controller.updateDay('02');
    controller.updateMonth('06');
    controller.updateYear('2026');
    controller.updateAddress('Calle 1');
    var draftTapped = false;
    var publishTapped = false;
    var closeTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EventCreationTemplate(
          controller: controller,
          linkController: linkController,
          onPickAttachments: () => controller.addAttachment(
            const EventAttachment(name: 'afiche.png', sizeBytes: 1024),
          ),
          onAddLink: () {
            controller.addLink(linkController.text);
            linkController.clear();
          },
          onClose: () => closeTapped = true,
          onDraft: () => draftTapped = true,
          onPublish: () => publishTapped = true,
        ),
      ),
    );

    expect(find.text('¡Empecemos!'), findsOneWidget);
    expect(find.text('Finaliza al día siguiente'), findsOneWidget);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi negocio'));
    await tester.pumpAndSettle();
    expect(controller.selectedBusiness?.id, 'business-1');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¡Dale vida!'), findsOneWidget);
    expect(find.byTooltip('Volver al paso anterior'), findsOneWidget);
    await tester.tap(find.text('Subir archivos'));
    await tester.pumpAndSettle();
    expect(find.text('afiche.png'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Descripción de prueba');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(controller.isPaid, isTrue);
    final paidSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(paidSwitch.activeThumbColor, EventCreationColors.blue);
    expect(paidSwitch.activeTrackColor, EventCreationColors.activeSwitchTrack);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¡Ya casi!'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(controller.adultsOnly, isTrue);
    await tester.enterText(
      find.byType(TextFormField),
      'https://instagram.com/evento',
    );
    await tester.tap(find.byTooltip('Añadir enlace'));
    await tester.pump();
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.byType(EventLinkPreview), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'https://www.youtube.com/watch?v=abc',
    );
    await tester.tap(find.byTooltip('Añadir enlace'));
    await tester.pump();
    expect(find.text('Instagram +1'), findsOneWidget);
    await tester.tap(find.text('Instagram +1'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar enlace de Instagram'));
    await tester.pumpAndSettle();
    expect(controller.links, hasLength(1));
    Navigator.of(tester.element(find.text('Enlaces del evento'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('YouTube'), findsOneWidget);

    await tester.tap(find.text('Guardar Borrador'));
    await tester.tap(find.text('Publicar evento'));
    expect(draftTapped, isTrue);
    expect(publishTapped, isTrue);

    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('¡Dale vida!'), findsOneWidget);
    expect(find.text('Descripción de prueba'), findsOneWidget);
    expect(controller.attachments.single.name, 'afiche.png');
    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('¡Empecemos!'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar crear evento'));
    expect(closeTapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('borrador muestra aviso y publicar regresa con el evento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 822);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EventCreationController(now: () => DateTime(2026, 6, 1));
    addTearDown(controller.dispose);
    controller.updateName('Concierto nocturno');
    controller.updateCategory('Música');
    controller.updateStartTime(const TimeOfDay(hour: 22, minute: 30));
    controller.updateEndTime(const TimeOfDay(hour: 4, minute: 0));
    controller.updateDay('02');
    controller.updateMonth('06');
    controller.updateYear('2026');
    controller.updateAddress('Calle 1');
    expect(controller.next(), isTrue);
    expect(controller.next(), isTrue);
    CreatedEventPreview? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<CreatedEventPreview>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EventCreationPage(initialController: controller),
                  ),
                );
              },
              child: const Text('Abrir creación'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir creación'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar Borrador'));
    await tester.pump();
    expect(
      find.text('Borrador guardado temporalmente en esta pantalla.'),
      findsOneWidget,
    );
    expect(find.byType(EventCreationPage), findsOneWidget);

    await tester.tap(find.text('Publicar evento'));
    await tester.pumpAndSettle();
    expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
    expect(
      find.text('Tu evento ha sido registrado correctamente.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(EventCreationPage), findsNothing);
    expect(result?.title, 'Concierto nocturno');
    expect(result?.startsAt, DateTime(2026, 6, 2, 22, 30));
    expect(result?.endsAt, DateTime(2026, 6, 3, 4));
  });
}
