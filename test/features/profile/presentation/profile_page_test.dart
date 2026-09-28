import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:frontend/features/profile/presentation/pages/settings_page.dart';
import 'package:frontend/features/profile/presentation/profile_providers.dart';
import 'package:frontend/features/profile/presentation/organisms/profile_section_panel.dart';
import 'package:frontend/features/profile/presentation/atoms/profile_section_tab.dart';
import 'package:frontend/features/navigation/presentation/molecules/floating_nav_bar.dart';
import 'package:frontend/features/navigation/presentation/organisms/custom_bottom_nav.dart';

void main() {
  const user = User(
    id: 1,
    username: 'juan',
    firstName: 'Juan',
    lastName: 'Chávez',
    email: 'juan@example.com',
    isActive: true,
  );

  testWidgets('perfil muestra datos reales y cambia de sección', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myProfileProvider.overrideWith((ref) async => user)],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Juan Chávez'), findsAtLeastNWidgets(1));
    expect(find.text('28 Amigos'), findsNothing);
    await tester.tap(find.text('Amigos').first);
    await tester.pumpAndSettle();
    expect(find.text('Tus amigos'), findsOneWidget);
    await tester.tap(find.text('Favoritos').first);
    await tester.pumpAndSettle();
    expect(find.text('Tus favoritos'), findsOneWidget);
  });

  testWidgets('configuración muestra cierre de sesión y apartados futuros', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myProfileProvider.overrideWith((ref) async => user)],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preguntas frecuentes'), findsOneWidget);
    expect(find.text('Términos del servicio'), findsOneWidget);
    expect(find.text('Política de usuario'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets(
    'el panel amarillo sigue la pestaña y el aviso queda sobre el navbar',
    (tester) async {
      tester.view.physicalSize = const Size(440, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [myProfileProvider.overrideWith((ref) async => user)],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(children: [ProfilePage(), CustomBottomNav()]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final panel = find.byType(ProfileSectionPanel);
      final usernameBottom = tester.getBottomLeft(find.text('@juan').first).dy;
      final tabsTop = tester
          .getTopLeft(find.byType(ProfileSectionTab).first)
          .dy;
      expect(tabsTop - usernameBottom, greaterThanOrEqualTo(16));
      Path yellowPath() => tester
          .widget<ClipPath>(
            find.descendant(of: panel, matching: find.byType(ClipPath)),
          )
          .clipper!
          .getClip(tester.getSize(panel));

      expect(yellowPath().contains(const Offset(356, 20)), isTrue);
      expect(yellowPath().contains(const Offset(84, 20)), isFalse);
      final hintBottom = tester
          .getBottomLeft(
            find.text('Edita tus datos e intereses desde Configuración.'),
          )
          .dy;
      final navTop = tester.getTopLeft(find.byType(FloatingNavBar)).dy;
      expect(hintBottom, lessThan(navTop));

      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();
      expect(yellowPath().contains(const Offset(84, 20)), isTrue);
      expect(yellowPath().contains(const Offset(356, 20)), isFalse);
    },
  );

  testWidgets('el saliente no recorta el panel en pestañas ni transiciones', (
    tester,
  ) async {
    for (final width in [360.0, 393.0, 440.0]) {
      var section = 2;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) => ProfileSectionPanel(
                    section: section,
                    onSectionSelected: (value) =>
                        setState(() => section = value),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      void expectContinuousPanel() {
        final panel = find.byType(ProfileSectionPanel);
        final size = tester.getSize(panel);
        final path = tester
            .widget<ClipPath>(
              find.descendant(of: panel, matching: find.byType(ClipPath)),
            )
            .clipper!
            .getClip(size);
        final body = RRect.fromRectAndRadius(
          Rect.fromLTRB(0, 55, size.width, size.height),
          const Radius.circular(40),
        );
        for (var y = 56.0; y < 96; y += 2) {
          for (var x = 1.0; x < size.width; x += 2) {
            final point = Offset(x, y);
            if (body.contains(point)) {
              expect(
                path.contains(point),
                isTrue,
                reason: 'Corte en $point, ancho $width, sección $section',
              );
            }
          }
        }
      }

      expectContinuousPanel();
      for (final label in ['Favoritos', 'Amigos', 'Perfil']) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expectContinuousPanel();
        await tester.pumpAndSettle();
        expectContinuousPanel();
      }
      expect(tester.takeException(), isNull);
    }
  });
}
