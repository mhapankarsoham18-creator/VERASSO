import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/services/content_recommendation_service.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/recommendations/presentation/for_you_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/features/social/data/feed_repository.dart';

import '../../mocks.dart';

void main() {
  late MockFeedRepository mockFeedRepository;
  late MockContentRecommendationService mockRecommendationService;

  setUp(() {
    mockFeedRepository = MockFeedRepository();
    mockRecommendationService = MockContentRecommendationService();
  });

  testWidgets('ForYouScreen shows login prompt when unauthenticated',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => null),
          themeControllerProvider.overrideWith((ref) => ThemeController()
            ..state = AppThemeState(
              mode: ThemeMode.system,
              primaryColor: Colors.blue,
              accentColor: Colors.blueAccent,
              isPowerSaveMode: true,
            )),
        ],
        child: const MaterialApp(home: ForYouScreen()),
      ),
    );

    expect(find.text('Authentication Required'), findsOneWidget);
  });

  testWidgets('ForYouScreen loads and shows recommendations', (tester) async {
    final testProfile = Profile(
      id: 'user1',
      username: 'tester',
      fullName: 'Test User',
      interests: ['coding'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => testProfile),
          feedRepositoryProvider.overrideWithValue(mockFeedRepository),
          contentRecommendationServiceProvider
              .overrideWithValue(mockRecommendationService),
          themeControllerProvider.overrideWith((ref) => ThemeController()
            ..state = AppThemeState(
              mode: ThemeMode.system,
              primaryColor: Colors.blue,
              accentColor: Colors.blueAccent,
              isPowerSaveMode: true,
            )),
        ],
        child: const MaterialApp(home: ForYouScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify sections exist
    expect(find.text('Sims for You'), findsOneWidget);
    expect(find.text('Trending in Network'), findsOneWidget);
  });
}
