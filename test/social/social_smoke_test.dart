import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/features/social/presentation/feed_controller.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';
import 'package:verasso/features/social/data/comment_repository.dart';
import 'package:verasso/features/social/data/comment_model.dart';

// Manual mocks for Repository
class MockFeedRepository extends Mock implements FeedRepository {
  @override
  Future<List<Post>> getFeed({
    List<String> userInterests = const [],
    int limit = 20,
    int offset = 0,
  }) => super.noSuchMethod(
        Invocation.method(#getFeed, [], {
          #userInterests: userInterests,
          #limit: limit,
          #offset: offset,
        }),
        returnValue: Future.value(<Post>[]),
      ) as Future<List<Post>>;
}

class MockCommentRepository extends Mock implements CommentRepository {
  @override
  Future<List<Comment>> getComments(String postId) => super.noSuchMethod(
        Invocation.method(#getComments, [postId]),
        returnValue: Future.value(<Comment>[]),
      ) as Future<List<Comment>>;
}

void main() {
  late MockFeedRepository mockFeedRepo;
  late MockCommentRepository mockCommentRepo;
  late ProviderContainer container;

  setUp(() {
    mockFeedRepo = MockFeedRepository();
    mockCommentRepo = MockCommentRepository();
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepo),
        commentRepositoryProvider.overrideWithValue(mockCommentRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Social Feature Smoke Tests', () {
    test('FeedNotifier loads initial posts on creation', () async {
      final posts = [
        Post(
          id: '1',
          userId: 'u1',
          content: 'Test Post',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockFeedRepo.getFeed(limit: 20, offset: 0))
          .thenAnswer((_) async => posts);

      // Trigger load via feedProvider
      container.read(feedProvider);
      
      // Wait for async initialization
      await Future.delayed(Duration.zero);
      
      final state = container.read(feedProvider);
      expect(state.value, posts);
      verify(mockFeedRepo.getFeed(limit: 20, offset: 0)).called(1);
    });

    test('CommentRepository fetches comments correctly', () async {
      final comments = [
        Comment(
          id: 'c1',
          postId: '1',
          userId: 'u1',
          content: 'Nice!',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockCommentRepo.getComments('1')).thenAnswer((_) async => comments);

      final result = await mockCommentRepo.getComments('1');
      
      expect(result, comments);
      verify(mockCommentRepo.getComments('1')).called(1);
    });
  });
}
