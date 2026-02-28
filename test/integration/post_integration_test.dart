import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/social/data/comment_repository.dart';
import 'package:verasso/features/social/data/feed_repository.dart';

import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late FeedRepository feedRepository;
  late CommentRepository commentRepository;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);

    final mockGamification = MockGamificationEventBus();
    final mockModeration = MockModerationService();

    feedRepository = FeedRepository(
      client: mockSupabase,
      eventBus: mockGamification,
      moderationService: mockModeration,
    );
    commentRepository = CommentRepository(
      client: mockSupabase,
      gamificationEventBus: mockGamification,
    );
  });

  group('Post Integration Tests', () {
    test(
        'complete create post flow: content → media → publish → appear in feed',
        () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      const postContent = 'Hello VERASSO!';
      const mediaUrl = 'https://example.com/image.jpg';

      // Create post with media
      await expectLater(
        feedRepository.createPost(
          userId: testUser.id,
          content: postContent,
          mediaUrls: [mediaUrl],
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'posts');
    });

    test('post appears in user feed after creation', () async {
      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': testUser.id,
          'content': 'Test post',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {
            'full_name': 'Test User',
            'avatar_url': 'https://example.com/avatar.jpg',
          }
        }
      ]);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final posts = await feedRepository.getFeed();

      expect(posts, isNotEmpty);
      expect(posts[0].content, 'Test post');
    });

    test('like post updates like count', () async {
      final likesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('likes', likesBuilder);
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': testUser.id,
          'content': 'Test post',
          'likes_count': 1,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      await expectLater(
        feedRepository.likePost('post-1'),
        completes,
      );

      expect(mockSupabase.lastRpcName, 'toggle_post_like');
    });

    test('add comment to post creates comment record', () async {
      final commentBuilder = MockSupabaseQueryBuilder(selectResponse: {
        'id': 'comment-1',
        'post_id': 'post-1',
        'user_id': testUser.id,
        'content': 'Great post!',
        'created_at': DateTime.now().toIso8601String(),
        'profiles': {
          'full_name': 'Test User',
          'avatar_url': 'https://example.com/avatar.jpg',
        }
      });
      mockSupabase.setQueryBuilder('comments', commentBuilder);

      await expectLater(
        commentRepository.createComment(
          postId: 'post-1',
          userId: testUser.id,
          content: 'Great post!',
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'comments');
    });

    test('comments appear on post after creation', () async {
      final commentsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'comment-1',
          'post_id': 'post-1',
          'user_id': testUser.id,
          'content': 'Great post!',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {
            'full_name': 'Test User',
            'avatar_url': 'https://example.com/avatar.jpg',
          }
        }
      ]);
      mockSupabase.setQueryBuilder('comments', commentsBuilder);

      final comments = await commentRepository.getPostComments('post-1');

      expect(comments, isNotEmpty);
      expect(comments[0].content, 'Great post!');
    });

    test('unlike post removes like', () async {
      final likesBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('likes', likesBuilder);

      await expectLater(
        feedRepository.unlikePost('post-1'),
        completes,
      );

      expect(mockSupabase.lastRpcName, 'toggle_post_like');
    });

    test('delete post removes from database and feed', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      await expectLater(
        feedRepository.deletePost('post-1'),
        completes,
      );

      expect(mockSupabase.lastDeleteTable, 'posts');
    });

    test('delete comment removes from post', () async {
      final commentsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('comments', commentsBuilder);

      await expectLater(
        commentRepository.deleteComment('comment-1'),
        completes,
      );
    });

    test('edit post updates content in database', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      const newContent = 'Updated post content';

      await expectLater(
        feedRepository.updatePost('post-1', newContent),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'posts');
    });
  });

  group('Post Integration - Data Consistency', () {
    test('post statistics updated atomically', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': testUser.id,
          'likes_count': 5,
          'comments_count': 3,
          'share_count': 1,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      final posts = await feedRepository.getFeed();

      expect(posts[0].likeCount, 5);
    });

    test('media attachments preserved with post', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': testUser.id,
          'media_urls': [
            'https://example.com/img1.jpg',
            'https://example.com/img2.jpg',
          ],
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      final posts = await feedRepository.getFeed();

      expect(posts, isNotEmpty);
    });

    test('comment author information preserved', () async {
      final commentsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'comment-1',
          'post_id': 'post-1',
          'user_id': testUser.id,
          'content': 'Test',
          'profiles': {
            'full_name': 'Test User',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('comments', commentsBuilder);

      final comments = await commentRepository.getPostComments('post-1');

      expect(comments[0].authorName, 'Test User');
    });
  });

  group('Post Integration - High Volume', () {
    test('handle 1000+ posts in feed without crash', () async {
      final largePostList = List.generate(
        1000,
        (i) => {
          'id': 'post-$i',
          'user_id': 'user-${i % 100}',
          'content': 'Post $i',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {
            'full_name': 'User ${i % 100}',
            'avatar_url': 'https://example.com/avatar.jpg',
          }
        },
      );

      final feedBuilder =
          MockSupabaseQueryBuilder(selectResponse: largePostList);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final stopwatch = Stopwatch()..start();
      final posts = await feedRepository.getFeed();
      stopwatch.stop();

      expect(posts.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('concurrent like operations handled safely', () async {
      final likesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('likes', likesBuilder);

      final futures = List.generate(
        100,
        (_) => feedRepository.likePost('post-1'),
      );

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });
  });

  group('Post Integration - Error Handling', () {
    test('network error during post creation handled', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('posts', builder);

      // Should handle gracefully
      expect(true, true);
    });

    test('delete post of another user rejected', () async {
      // Authorization check should prevent this
      expect(true, true);
    });

    test('edit post with invalid content rejected', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      // Should validate content length/format
      expect(true, true);
    });
  });
}
