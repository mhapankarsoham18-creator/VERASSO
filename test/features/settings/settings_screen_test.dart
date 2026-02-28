import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/settings_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../mocks.dart';

// We need to subclass SettingsScreen to override the _BiometricAuthTile state
// or ensure BiometricAuthService is mockable via GetIt or Riverpod if it was provided there.
// However, looking at _BiometricAuthTile, it instantiates BiometricAuthService directly:
// final _biometricService = BiometricAuthService();
// This makes it hard to test without DI.
// For now, we will test the parts of SettingsScreen that rely on Riverpod.

void main() {
  late MockThemeController mockThemeController;
  late MockProfileController mockProfileController;
  late MockPrivacySettingsNotifier mockPrivacySettingsNotifier;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockThemeController = MockThemeController();
    mockProfileController = MockProfileController();
    mockPrivacySettingsNotifier = MockPrivacySettingsNotifier();
    mockAuthRepository = MockAuthRepository();
  });

  final testUser = DomainAuthUser(id: 'User1', email: 'user1@example.com');
  final testProfile = Profile(
    id: 'User1',
    username: 'user1',
    fullName: 'User One',
    isPrivate: true, // Test initial state
  );

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testUser),
        themeControllerProvider.overrideWith((ref) => mockThemeController),
        profileControllerProvider.overrideWith((ref) => mockProfileController),
        privacySettingsProvider
            .overrideWith((ref) => mockPrivacySettingsNotifier),
        authControllerProvider.overrideWith((ref) => AuthController(
            mockAuthRepository,
            ref,
            MockTokenStorageService(),
            MockOfflineSecurityService())),
        userProfileProvider.overrideWithValue(AsyncValue.data(testProfile)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all settings sections', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Connectivity'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Security'), findsWidgets); // Used in two places
      expect(find.text('Privacy Display'), findsOneWidget);

      await tester.ensureVisible(find.text('Privacy & Legal'));
      expect(find.text('Privacy & Legal'), findsOneWidget);

      await tester.ensureVisible(find.text('Support'));
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('renders Power Save Mode switch', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Power Save Mode'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('renders Private Account switch with correct state',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      final switchTile = find.widgetWithText(SwitchListTile, 'Private Account');
      // The actual text might be from localizations, but in test it defaults to English if not overridden.
      // However, we should ensure the text matches the localization key.
      expect(switchTile, findsOneWidget);

      final switchWidget = tester.widget<SwitchListTile>(switchTile);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('sign out button is present', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      final signOutFinder = find.text('Sign Out');

      // Scroll until the button is visible
      await tester.scrollUntilVisible(
        signOutFinder,
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(signOutFinder, findsOneWidget);
    });
  });
}
