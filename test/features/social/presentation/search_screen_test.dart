import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/news/data/news_repository.dart';
import 'package:verasso/features/news/domain/news_model.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/features/social/data/community_repository.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/presentation/search_controller.dart'
    as sc;
import 'package:verasso/features/social/presentation/search_screen.dart'; // Aliased as DiscoverScreen
import 'package:verasso/features/talent/data/talent_profile_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSearchController mockSearchController;
  late MockFeedRepository mockFeedRepository;
  late MockCommunityRepository mockCommunityRepository;
  late MockCourseRepository mockCourseRepository;
  late MockProfileRepository mockProfileRepository;
  late MockTalentProfileRepository mockTalentProfileRepository;
  late MockNewsRepository mockNewsRepository;

  setUp(() {
    mockSearchController = MockSearchController();
    mockFeedRepository = MockFeedRepository();
    mockCommunityRepository = MockCommunityRepository();
    mockCourseRepository = MockCourseRepository();
    mockProfileRepository = MockProfileRepository();
    mockTalentProfileRepository = MockTalentProfileRepository();
    mockNewsRepository = MockNewsRepository();

    // Stub required methods
    mockFeedRepository.getFeedStub =
        ({limit = 20, offset = 0, userInterests = const []}) async => [];
    mockCommunityRepository.getRecommendedCommunitiesStub = () async => [];
    mockCourseRepository.getPublishedCoursesStub = () async => [];
    mockCommunityRepository.searchCommunitiesStub = (query) async => [];
    mockTalentProfileRepository.searchMentorsStub = (query) async => [];
    mockNewsRepository.watchArticlesStub =
        ({featuredOnly = false, subject}) => Stream.value([]);
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        sc.searchControllerProvider.overrideWith((ref) => mockSearchController),
        feedRepositoryProvider.overrideWithValue(mockFeedRepository),
        communityRepositoryProvider.overrideWithValue(mockCommunityRepository),
        courseRepositoryProvider.overrideWithValue(mockCourseRepository),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        talentProfileRepositoryProvider
            .overrideWithValue(mockTalentProfileRepository),
        newsRepositoryProvider.overrideWithValue(mockNewsRepository),
        // Disable infinite animations in LiquidBackground
        themeControllerProvider.overrideWith((ref) => MockThemeController()),
      ],
      child: const MaterialApp(
        home: DiscoverScreen(),
      ),
    );
  }

  group('DiscoverScreen (SearchScreen) Widget Tests', () {
    testWidgets('renders search bar and initial sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Discover people & ideas...'), findsOneWidget);
      expect(find.text('Explore Community'), findsOneWidget);
    });

    testWidgets('entering text in search bar triggers search',
        (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pump(const Duration(milliseconds: 600)); // Debounce
      await tester.pumpAndSettle();

      expect(find.text('Flutter'), findsOneWidget);
    });
  });
}

class MockNewsRepository extends Fake implements NewsRepository {
  Stream<List<NewsArticle>> Function({String? subject, bool featuredOnly})?
      watchArticlesStub;

  @override
  Stream<List<NewsArticle>> watchArticles(
          {String? subject, bool featuredOnly = false}) =>
      watchArticlesStub?.call(subject: subject, featuredOnly: featuredOnly) ??
      Stream.value([]);
}

class MockSearchController extends sc.SearchController {
  MockSearchController()
      : super(
          MockProfileRepository(),
          MockFeedRepository(),
          MockCourseRepository(),
          MockTalentProfileRepository(),
          MockCommunityRepository(),
        );

  @override
  Future<void> search(String query) async {
    // No-op for mock
  }
}
