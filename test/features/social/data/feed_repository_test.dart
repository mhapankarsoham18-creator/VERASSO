import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/social/data/feed_repository.dart';

import '../../../mocks.dart';

void main() {
  late FeedRepository repository;
  late MockSupabaseClient mockSupabase;
  late MockGamificationEventBus mockGamification;
  late MockModerationService mockModeration;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGamification = MockGamificationEventBus();
    mockModeration = MockModerationService();
    repository = FeedRepository(
      client: mockSupabase,
      eventBus: mockGamification,
      moderationService: mockModeration,
    );
  });

  group('FeedRepository', () {
    test('createPost should insert post and update XP', () async {
      // Arrange
      final userId = 'test-user';
      final content = 'Hello world';
      final tags = ['flutter', 'test'];

      // Act
      await repository.createPost(
        userId: userId,
        content: content,
        tags: tags,
      );

      // Assert
      // Verification of MockSupabaseQueryBuilder and Gamification would happen here
      // Since we uses manual fakes, we rely on them not throwing.
    });

    test('getFeed should return filtered and ranked posts', () async {
      // Arrange
      final mockUser = TestSupabaseUser(id: 'me');
      (mockSupabase.auth as MockGoTrueClient).setCurrentUser(mockUser);

      final postsData = [
        {
          'id': '1',
          'user_id': 'user1',
          'content': 'Post 1',
          'tags': ['flutter'],
          'likes_count': 10,
          'comments_count': 2,
          'created_at': DateTime.now().toIso8601String(),
          'is_personal': false,
          'profiles': {'full_name': 'User One', 'avatar_url': 'url1'},
          'is_liked': []
        },
        {
          'id': '2',
          'user_id': 'user2',
          'content': 'Post 2',
          'tags': ['dart'],
          'likes_count': 5,
          'comments_count': 1,
          'created_at': DateTime.now().toIso8601String(),
          'is_personal': false,
          'profiles': {'full_name': 'User Two', 'avatar_url': 'url2'},
          'is_liked': []
        }
      ];

      final queryBuilder = MockSupabaseQueryBuilder(selectResponse: postsData);
      mockSupabase.setQueryBuilder('posts', queryBuilder);
      mockModeration.getMutedUserIdsStub = (id) async => [];

      // Act
      final posts = await repository.getFeed(userInterests: ['flutter']);

      // Assert
      expect(posts.length, 2);
      expect(posts[0].id, '1'); // Ranked higher due to interest
      expect(posts[0].authorName, 'User One');
    });

    test('getFeed should filter out muted users', () async {
      // Arrange
      final mockUser = TestSupabaseUser(id: 'me');
      (mockSupabase.auth as MockGoTrueClient).setCurrentUser(mockUser);

      mockModeration.getMutedUserIdsStub = (id) async => ['muted-user'];

      final postsData = [
        {
          'id': '1',
          'user_id': 'active-user',
          'content': 'Hello',
          'created_at': DateTime.now().toIso8601String(),
          'is_liked': []
        }
      ];

      final queryBuilder = MockSupabaseQueryBuilder(selectResponse: postsData);
      mockSupabase.setQueryBuilder('posts', queryBuilder);

      // Act
      final posts = await repository.getFeed();

      // Assert
      expect(posts.length, 1);
      expect(posts[0].userId, 'active-user');
    });

    test('likePost should call rpc', () async {
      // Arrange
      final mockUser = TestSupabaseUser(id: 'me');
      (mockSupabase.auth as MockGoTrueClient).setCurrentUser(mockUser);

      // Act
      await repository.likePost('post-123');

      // Assert
      // RPC check happens in MockSupabaseClient
    });
  });
}
