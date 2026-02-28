import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/social/data/comment_repository.dart';

import '../../../mocks.dart';

void main() {
  late CommentRepository repository;
  late MockSupabaseClient mockSupabase;
  late MockGamificationEventBus mockGamification;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGamification = MockGamificationEventBus();
    repository = CommentRepository(
      client: mockSupabase,
      gamificationEventBus: mockGamification,
    );
  });

  group('CommentRepository', () {
    test('addComment should insert comment and return it with profile data',
        () async {
      // Arrange
      final mockUser = TestSupabaseUser(id: 'test-user');
      (mockSupabase.auth as MockGoTrueClient).setCurrentUser(mockUser);

      final commentData = {
        'id': 'c1',
        'post_id': 'p1',
        'user_id': 'test-user',
        'content': 'Great post!',
        'created_at': DateTime.now().toIso8601String(),
        'profiles': {'full_name': 'Test User', 'avatar_url': 'avatar-url'}
      };

      final queryBuilder =
          MockSupabaseQueryBuilder(selectResponse: [commentData]);
      mockSupabase.setQueryBuilder('comments', queryBuilder);

      // Act
      final comment = await repository.addComment(
        postId: 'p1',
        content: 'Great post!',
      );

      // Assert
      expect(comment.id, 'c1');
      expect(comment.authorName, 'Test User');
    });

    test('getComments should return list of comments', () async {
      // Arrange
      final commentsData = [
        {
          'id': 'c1',
          'post_id': 'p1',
          'user_id': 'u1',
          'content': 'Comment 1',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {'full_name': 'User One', 'avatar_url': 'url1'}
        },
        {
          'id': 'c2',
          'post_id': 'p1',
          'user_id': 'u2',
          'content': 'Comment 2',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {'full_name': 'User Two', 'avatar_url': 'url2'}
        }
      ];

      final queryBuilder =
          MockSupabaseQueryBuilder(selectResponse: commentsData);
      mockSupabase.setQueryBuilder('comments', queryBuilder);

      // Act
      final comments = await repository.getComments('p1');

      // Assert
      expect(comments.length, 2);
      expect(comments[0].content, 'Comment 1');
      expect(comments[1].authorName, 'User Two');
    });
  });
}
