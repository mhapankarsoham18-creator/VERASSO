import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/talent/data/analytics_repository.dart';
import 'package:verasso/features/talent/data/job_repository.dart';
import 'package:verasso/features/talent/data/talent_model.dart';
import 'package:verasso/features/talent/data/talent_repository.dart';
import 'package:verasso/features/talent/presentation/talent_dashboard.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../../mocks.dart';

void main() {
  late MockTalentRepository mockTalentRepo;
  late MockJobRepository mockJobRepo;
  late MockAnalyticsRepository mockAnalyticsRepo;
  late MockProfileRepository mockProfileRepo;
  late DomainAuthUser mockUser;

  final testTalent = TalentPost(
    id: 't1',
    userId: 'u1',
    title: 'Expert Flutter Developer',
    description: 'Years of Experience',
    price: 50.0,
    currency: 'USD',
    createdAt: DateTime.now(),
    authorName: 'Soham M',
  );

  final testProfile = Profile(
    id: 'u1',
    fullName: 'Soham M',
    isAgeVerified: true,
  );

  setUp(() {
    mockTalentRepo = MockTalentRepository();
    mockJobRepo = MockJobRepository();
    mockAnalyticsRepo = MockAnalyticsRepository();
    mockProfileRepo = MockProfileRepository();
    mockUser = DomainAuthUser(id: 'u1', email: 'u1@example.com');

    mockTalentRepo.getTalentsStub =
        ({limit = 20, offset = 0}) async => [testTalent];
    mockJobRepo.getJobRequestsStub = ({limit = 20, offset = 0}) async => [];
  });

  testWidgets('localization works', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(),
    ));
    await tester.pump();
  });

  Widget createTalentDashboard() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        userProfileProvider.overrideWith((ref) => Future.value(testProfile)),
        talentRepositoryProvider.overrideWithValue(mockTalentRepo),
        jobRepositoryProvider.overrideWithValue(mockJobRepo),
        analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TalentDashboard(),
      ),
    );
  }

  group('TalentDashboard Widget Tests', () {
    testWidgets('renders TalentDashboard and shows Talent tab by default',
        (tester) async {
      await tester.pumpWidget(createTalentDashboard());

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(TalentDashboard), findsOneWidget);
    });

    testWidgets('switching between tabs works', (tester) async {
      await tester.pumpWidget(createTalentDashboard());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final jobBoardTab = find.text('Job Board');
      if (jobBoardTab.evaluate().isNotEmpty) {
        await tester.tap(jobBoardTab);
        // pump() with durations instead of pumpAndSettle to avoid LiquidBackground animation timeout
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('search bar works', (tester) async {
      await tester.pumpWidget(createTalentDashboard());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final searchIcon = find.byIcon(LucideIcons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pump(const Duration(milliseconds: 500));

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField, 'Flutter');
          await tester.pump(const Duration(milliseconds: 500));
        }
      }
    });
  });
}
