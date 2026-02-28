import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/mastery_signature_service.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/learning/data/assessment_models.dart';
import 'package:verasso/features/learning/data/assessment_repository.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/profile/presentation/profile_screen.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../mocks.dart';

void main() {
  late MockProfileController mockProfileController;
  late MockPrivacySettingsNotifier mockPrivacySettingsNotifier;
  late MockMasterySignatureService mockMasterySignatureService;
  final testUser =
      DomainAuthUser(id: 'test-user-id', email: 'test@example.com');
  final testProfile = Profile(
    id: 'test-user-id',
    username: 'valid_user',
    fullName: 'Test User',
    bio: 'This is a test bio',
    role: 'mentor',
    interests: ['Coding', 'Flutter'],
    trustScore: 100,
    isPrivate: false,
    followersCount: 10,
    followingCount: 5,
    postsCount: 20,
  );

  final testCertificates = [
    Certificate(
      id: 'cert-1',
      studentId: 'test-user-id',
      courseId: 'course-1',
      issuedAt: DateTime.now(),
      verificationCode: 'V-CODE-1',
      courseTitle: 'Coding Mastery',
    ),
  ];

  setUp(() {
    mockProfileController = MockProfileController();
    mockPrivacySettingsNotifier = MockPrivacySettingsNotifier();
    mockMasterySignatureService = MockMasterySignatureService();
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testUser),
        profileControllerProvider.overrideWith((ref) => mockProfileController),
        privacySettingsProvider
            .overrideWith((ref) => mockPrivacySettingsNotifier),
        masterySignatureServiceProvider
            .overrideWithValue(mockMasterySignatureService),
        userProfileProvider.overrideWithValue(AsyncValue.data(testProfile)),
        profileStatsProvider('test-user-id')
            .overrideWithValue(const AsyncValue.data({'friends_count': 42})),
        userCertificatesProvider('test-user-id')
            .overrideWithValue(AsyncValue.data(testCertificates)),
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('displays user profile data correctly',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@valid_user'), findsOneWidget);
      expect(find.text('This is a test bio'), findsOneWidget);
      expect(find.text('MENTOR'), findsOneWidget);
      expect(find.text('Coding'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('displays stats correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      // Trust Score
      expect(find.text('100'), findsOneWidget);
      // Friends (from stats provider)
      expect(find.text('42'), findsOneWidget);
      // Following
      expect(find.text('5'), findsOneWidget);
      // Followers
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows edit profile button', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('export transcript requires interaction',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      final exportBtn = find.text('Export Verified Transcript');
      await tester.ensureVisible(exportBtn);
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Verified Transcript'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('ProfileScreen Accessibility', () {
    testWidgets('semantic labels are present', (tester) async {
      await tester.pumpWidget(createSubject());
      expect(find.byIcon(LucideIcons.settings), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
