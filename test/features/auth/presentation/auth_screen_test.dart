import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/security/biometric_auth_service.dart';
import 'package:verasso/core/security/security_providers.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/auth/presentation/auth_screen.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../../mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    when(mockPrefs.getString('theme_mode')).thenReturn('');
    when(mockPrefs.getBool('theme_power_save')).thenReturn(false);
    when(mockPrefs.getInt('theme_primary_color')).thenReturn(0);
  });

  Widget createAuthScreen({bool showResetView = false}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        tokenStorageServiceProvider
            .overrideWithValue(MockTokenStorageService()),
        offlineSecurityServiceProvider
            .overrideWithValue(MockOfflineSecurityService()),
        offlineStorageServiceProvider
            .overrideWithValue(MockOfflineStorageService()),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
        biometricAuthServiceProvider
            .overrideWith((ref) => MockBiometricAuthService()),
        privacySettingsProvider
            .overrideWith((ref) => PrivacySettingsNotifier(mockPrefs, ref)),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', ''),
        ],
        home: AuthScreen(showResetView: showResetView),
      ),
    );
  }

  group('AuthScreen Widget Tests', () {
    testWidgets('renders initial login state correctly', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pump(); // Allow thermal code and other local state to init

      expect(find.text('Welcome Back, Pioneer'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Re-establishing data uplink'), findsOneWidget);
    });

    testWidgets('switches to signup view', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pump();

      // Find the toggle button - it's at the bottom
      final signupToggle = find.text('Create an account');
      expect(signupToggle, findsOneWidget);

      await tester.tap(signupToggle);
      await tester.pump();

      expect(find.text('Initiate Discovery'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Join the global neural network'), findsOneWidget);
    });

    testWidgets('switches to OTP login view', (tester) async {
      await tester.pumpWidget(createAuthScreen());
      await tester.pump();

      final otpToggle = find.text('Verify with Temporal Code');
      expect(otpToggle, findsOneWidget);

      await tester.tap(otpToggle);
      await tester.pump();

      expect(find.text('Use Master Password'), findsOneWidget);
      expect(find.byType(TextField),
          findsNWidgets(1)); // Only Email, Password is gone
    });

    testWidgets('shows reset password view', (tester) async {
      await tester.pumpWidget(createAuthScreen(showResetView: true));
      await tester.pumpAndSettle();

      expect(find.text('Reset Access'), findsOneWidget);
      expect(find.text('Enter your email to re-establish neural link'),
          findsOneWidget);
    });
  });
}
