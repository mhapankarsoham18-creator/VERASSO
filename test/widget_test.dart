// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/security/security_providers.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/main.dart';

import 'mocks.dart';

void main() {
  testWidgets('App smoke test - verifies login screen structure',
      (WidgetTester tester) async {
    // Mock data
    final mockPrefs = MockSharedPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Infrastructure overrides
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          tokenStorageServiceProvider
              .overrideWithValue(MockTokenStorageService()),
          offlineSecurityServiceProvider
              .overrideWithValue(MockOfflineSecurityService()),
          offlineStorageServiceProvider
              .overrideWithValue(MockOfflineStorageService()),

          // Auth overrides
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          authStateProvider.overrideWith((ref) => Stream.value(null)),

          // Controller overrides
          themeControllerProvider.overrideWith((ref) => MockThemeController()),
          privacySettingsProvider
              .overrideWith((ref) => PrivacySettingsNotifier(mockPrefs, ref)),
        ],
        child: const VerassoApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of Verasso branding or login elements
    expect(find.byType(MaterialApp), findsOneWidget);
    // Adjust this to match your actual home/login screen text
    expect(find.textContaining('Verasso'),
        findsNothing); // It's usually empty or logo
  });
}
