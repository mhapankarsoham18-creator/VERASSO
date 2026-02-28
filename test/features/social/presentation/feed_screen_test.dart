import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/core/security/moderation_service.dart';
import 'package:verasso/core/security/security_providers.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';
import 'package:verasso/features/social/data/saved_post_repository.dart';
import 'package:verasso/features/social/presentation/feed_screen.dart';
import 'package:verasso/features/social/presentation/stories_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../../mocks.dart';

void main() {
  late MockFeedRepository mockFeedRepo;
  late MockSavedPostRepository mockSavedPostRepo;
  late MockSharedPreferences mockPrefs;
  late MockModerationService mockModeration;
  late MockAuthRepository mockAuthRepo;
  late MockStoryRepository mockStoryRepo;

  final testPost = Post(
    id: 'post-1',
    userId: 'user-1',
    content: 'Test content for Verasso Feed',
    createdAt: DateTime.now(),
    authorName: 'Test Pioneer',
    likesCount: 10,
    commentsCount: 5,
  );

  setUp(() {
    // Initialize SharedPreferences for TutorialService
    SharedPreferences.setMockInitialValues({
      'tutorial_completed_feed_feature': true,
    });

    mockFeedRepo = MockFeedRepository();
    mockSavedPostRepo = MockSavedPostRepository();
    mockPrefs = MockSharedPreferences();
    mockModeration = MockModerationService();
    mockAuthRepo = MockAuthRepository();
    mockStoryRepo = MockStoryRepository();

    // FeedRepository stubs
    mockFeedRepo.getFeedStub = ({
      List<String> userInterests = const [],
      int limit = 20,
      int offset = 0,
    }) async =>
        [testPost];
    mockFeedRepo.watchFeedStub = () => Stream.value([testPost]);
    mockFeedRepo.getFollowingFeedStub = ({String? userId}) async => [testPost];
    mockFeedRepo.likePostStub = (postId) async {};

    // SavedPostRepository stubs
    mockSavedPostRepo.isSavedStub = (postId) async => false;
    mockSavedPostRepo.watchCollectionsStub = () => Stream.value([]);
    mockSavedPostRepo.getSavedPostsStub = () async => [];

    // StoryRepository stub
    mockStoryRepo.getActiveStoriesStub = () async => [];

    // ModerationService stub
    mockModeration.getMutedUserIdsStub = (userId) async => [];

    // SharedPreferences stubs
    when(mockPrefs.getString('theme_mode')).thenReturn('dark');
    when(mockPrefs.getString('privacy_settings')).thenReturn('{}');
    when(mockPrefs.getBool('theme_power_save')).thenReturn(false);
    when(mockPrefs.getInt('theme_primary_color')).thenReturn(0);
  });

  Widget createFeedScreen() {
    return ProviderScope(
      overrides: [
        // Foundation: repositories and services
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        feedRepositoryProvider.overrideWithValue(mockFeedRepo),
        savedPostRepositoryProvider.overrideWithValue(mockSavedPostRepo),
        storyRepositoryProvider.overrideWithValue(mockStoryRepo),
        moderationServiceProvider.overrideWithValue(mockModeration),
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        // Security fakes
        tokenStorageServiceProvider
            .overrideWithValue(MockTokenStorageService()),
        offlineSecurityServiceProvider
            .overrideWithValue(MockOfflineSecurityService()),
        offlineStorageServiceProvider
            .overrideWithValue(MockOfflineStorageService()),
        // Theme & Privacy
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
        privacySettingsProvider
            .overrideWith((ref) => PrivacySettingsNotifier(mockPrefs, ref)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeedScreen(),
      ),
    );
  }

  group('FeedScreen Widget Tests', () {
    testWidgets('renders feed screen and displays post', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      // Pump multiple frames to let async providers resolve and animations start
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(FeedScreen), findsOneWidget);
      expect(find.text('Test content for Verasso Feed'), findsOneWidget);
      expect(find.text('Test Pioneer'), findsOneWidget);
    });

    testWidgets('shows feed tab buttons', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('displays like count', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays comment count', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('has create post FAB', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsWidgets);
    });

    testWidgets('shows story carousel area', (tester) async {
      await tester.pumpWidget(createFeedScreen());
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // StoryCarousel renders "Your Story" add button even with empty stories
      expect(find.text('Your Story'), findsOneWidget);
    });
  });
}
