import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/domain/entities/user.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_controller.dart';
import 'package:frontend/features/authentication/presentation/controllers/authentication_state.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:frontend/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:frontend/features/profile/presentation/pages/interests_page.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:frontend/features/profile/presentation/pages/settings_page.dart';
import 'package:frontend/features/profile/presentation/profile_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

void main() {
  testWidgets(
    'perfil abre configuración, ambas opciones de edición e intereses y permite volver',
    (tester) async {
      const user = User(
        id: 1,
        username: 'juan',
        firstName: 'Juan',
        lastName: 'Chávez',
        email: 'juan@example.com',
        isActive: true,
      );
      final preferences = _MockPreferencesRepository();
      when(() => preferences.getInterests())
          .thenAnswer((_) async => [const Interest(id: 1, name: 'Música')]);
      when(() => preferences.getMyPreferences())
          .thenAnswer((_) async => ['Música']);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myProfileProvider.overrideWith((ref) async => user),
            preferencesRepositoryProvider.overrideWithValue(preferences),
            authenticationControllerProvider.overrideWithBuild(
              (ref, _) => const AuthenticationState.initial(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfilePage())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuración'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      for (final entry in ['Juan Chávez', 'Editar perfil']) {
        await tester.tap(find.text(entry));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfilePage), findsOneWidget);
        expect(find.text('juan@example.com'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);
      }

      await tester.tap(find.text('Mis intereses'));
      await tester.pumpAndSettle();
      expect(find.byType(InterestsPage), findsOneWidget);
      expect(
        find.text('Selecciona al menos 4 intereses (1/4)'),
        findsOneWidget,
      );
      verify(() => preferences.getMyPreferences()).called(1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Tu información'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
