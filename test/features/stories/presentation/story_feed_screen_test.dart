import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/features/stories/data/stories_provider.dart';
import 'package:verasso/features/stories/presentation/story_feed_screen.dart';
import 'package:verasso/services/stories_service.dart';

void main() {
  late MockStoriesService mockStoriesService;

  setUp(() {
    mockStoriesService = MockStoriesService();
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        storiesServiceProvider.overrideWithValue(mockStoriesService),
      ],
      child: const MaterialApp(
        home: Scaffold(body: StoryFeedScreen()),
      ),
    );
  }

  group('StoryFeedScreen Widget Tests', () {
    testWidgets('renders empty state when no stories',
        (WidgetTester tester) async {
      when(mockStoriesService.getActiveStories()).thenAnswer((_) async => []);
      when(mockStoriesService.getMyStories()).thenAnswer((_) async => []);

      await tester.pumpWidget(createSubject());
      // Initial shimmer
      await tester.pump();
      // Settle
      await tester.pumpAndSettle();

      expect(find.text('No stories available. Be the first to share!'),
          findsOneWidget);
    });

    testWidgets('renders stories when available', (WidgetTester tester) async {
      final story = StoryModel(
        id: '1',
        userId: 'u1',
        mediaUrl: 'http://example.com/image.jpg',
        mediaType: 'image',
        duration: 5,
        viewsCount: 0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        username: 'alice',
      );

      when(mockStoriesService.getActiveStories())
          .thenAnswer((_) async => [story]);
      when(mockStoriesService.getMyStories()).thenAnswer((_) async => []);

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('alice'), findsOneWidget);
    });
  });
}

// Mock Services
class MockStoriesService extends Mock implements StoriesService {
  @override
  Future<List<StoryModel>> getActiveStories() async => super.noSuchMethod(
        Invocation.method(#getActiveStories, []),
        returnValue: Future.value(<StoryModel>[]),
        returnValueForMissingStub: Future.value(<StoryModel>[]),
      );

  @override
  Future<List<StoryModel>> getMyStories() async => super.noSuchMethod(
        Invocation.method(#getMyStories, []),
        returnValue: Future.value(<StoryModel>[]),
        returnValueForMissingStub: Future.value(<StoryModel>[]),
      );
}
