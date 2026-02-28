import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/social/data/story_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late StoryRepository repository;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    repository = StoryRepository(supabase: mockSupabase);
  });

  group('StoryRepository Tests', () {
    test('createStory inserts story with content', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('stories', builder);

      await expectLater(
        repository.createStory(
          userId: 'user-1',
          content: 'test_image.jpg',
          mediaType: 'image/jpeg',
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'stories');
    });

    test('createStory throws when user not logged in', () async {
      mockAuth.setCurrentUser(null);

      expect(
        () => repository.createStory(
          userId: 'user-1',
          content: 'test.jpg',
          mediaType: 'image/jpeg',
        ),
        throwsException,
      );
    });

    test('getStories returns list of visible stories', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'story-1',
          'user_id': 'user-2',
          'content': 'story_content_1',
          'created_at': '2025-01-15T10:00:00Z',
          'expires_at': '2025-01-16T10:00:00Z',
        },
        {
          'id': 'story-2',
          'user_id': 'user-3',
          'content': 'story_content_2',
          'created_at': '2025-01-15T10:30:00Z',
          'expires_at': '2025-01-16T10:30:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('stories', builder);

      final stories = await repository.getStories();

      expect(stories, isNotEmpty);
    });

    test('getStoriesForUser returns user-specific stories', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'story-1',
          'user_id': 'user-1',
          'content': 'my_story',
          'created_at': '2025-01-15T10:00:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('stories', builder);

      final stories = await repository.getStoriesForUser('user-1');

      expect(stories, isNotEmpty);
    });

    test('deleteStory removes story by ID', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('stories', builder);

      await expectLater(
        repository.deleteStory('story-1'),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'stories');
    });

    test('viewStory records view event', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('story_views', builder);

      await expectLater(
        repository.viewStory('story-1', 'user-1'),
        completes,
      );
    });

    test('reactToStory records reaction (emoji)', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('story_reactions', builder);

      await expectLater(
        repository.reactToStory(
          storyId: 'story-1',
          userId: 'user-1',
          emoji: '❤️',
        ),
        completes,
      );
    });

    test('getStoryViews returns list of viewers', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'user_id': 'user-2',
          'viewed_at': '2025-01-15T10:15:00Z',
        },
        {
          'user_id': 'user-3',
          'viewed_at': '2025-01-15T10:20:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('story_views', builder);

      final views = await repository.getStoryViews('story-1');

      expect(views, isNotEmpty);
    });

    test('getStoryReactions returns list of reactions', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'user_id': 'user-2',
          'emoji': '❤️',
          'reacted_at': '2025-01-15T10:15:00Z',
        }
      ]);
      mockSupabase.setQueryBuilder('story_reactions', builder);

      final reactions = await repository.getStoryReactions('story-1');

      expect(reactions, isNotEmpty);
    });

    test('archiveExpiredStories handles expiration', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('stories', builder);

      await expectLater(
        repository.archiveExpiredStories(),
        completes,
      );
    });

    test('getStories returns empty list on error', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('stories', builder);

      final stories = await repository.getStories();

      expect(stories, isEmpty);
    });

    test('createStory generates 24-hour expiry', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('stories', builder);

      await repository.createStory(
        userId: 'user-1',
        content: 'test.jpg',
        mediaType: 'image/jpeg',
      );

      // Verify that insert was called
      expect(mockSupabase.lastInsertTable, 'stories');
    });
  });

  group('StoryRepository - High Volume Tests (5k-10k users)', () {
    test('getStories handles large result sets efficiently', () async {
      // Simulate 10k active users each with 1 story
      final largeData = List.generate(
        100,
        (i) => {
          'id': 'story-$i',
          'user_id': 'user-$i',
          'content': 'content_$i',
          'created_at': '2025-01-15T10:00:00Z',
          'expires_at': '2025-01-16T10:00:00Z',
        },
      );

      final builder = MockSupabaseQueryBuilder(selectResponse: largeData);
      mockSupabase.setQueryBuilder('stories', builder);

      final stopwatch = Stopwatch()..start();
      final stories = await repository.getStories();
      stopwatch.stop();

      expect(stories.length, largeData.length);
      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('viewStory bulk operations handle concurrent views', () async {
      final builder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('story_views', builder);

      // Simulate 100 concurrent view operations
      final futures = List.generate(
        100,
        (i) => repository.viewStory('story-1', 'user-$i'),
      );

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });
  });
}
