import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/discovery/data/discovery_repository.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';

import '../../../mocks.dart';

void main() {
  late MockFeedRepository mockFeedRepo;
  late ProviderContainer container;

  Post makePost({
    String id = '1',
    List<String> tags = const [],
    int likesCount = 0,
    int commentsCount = 0,
    DateTime? createdAt,
  }) {
    return Post(
      id: id,
      userId: 'user-$id',
      content: 'Test post $id',
      tags: tags,
      likesCount: likesCount,
      commentsCount: commentsCount,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  setUp(() {
    mockFeedRepo = MockFeedRepository();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({Profile? profile}) {
    container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepo),
        userProfileProvider.overrideWith((ref) async => profile),
      ],
    );
    return container;
  }

  group('DiscoveryRepository', () {
    test('getDiscoveryFeed returns posts sorted by relevance score', () async {
      final profile = Profile(
        id: 'test-user',
        interests: ['flutter', 'dart'],
      );

      final posts = [
        makePost(id: '1', tags: ['python'], likesCount: 5),
        makePost(id: '2', tags: ['flutter', 'dart'], likesCount: 10),
        makePost(id: '3', tags: ['flutter'], likesCount: 2),
      ];

      mockFeedRepo.getFeedStub = ({
        List<String> userInterests = const [],
        int limit = 20,
        int offset = 0,
      }) =>
          Future.value(posts);

      final c = createContainer(profile: profile);

      // Let the userProfileProvider resolve
      await c.read(userProfileProvider.future);

      final repo = c.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryFeed();

      // Post 2 should be first (two exact matches + higher likes)
      // Post 3 should be second (one exact match)
      // Post 1 should be last (no matches, only popularity)
      expect(result.length, 3);
      expect(result[0].id, '2');
      expect(result[1].id, '3');
      expect(result[2].id, '1');
    });

    test('getDiscoveryFeed returns empty list when feed is empty', () async {
      final profile = Profile(
        id: 'test-user',
        interests: ['flutter'],
      );

      mockFeedRepo.getFeedStub = ({
        List<String> userInterests = const [],
        int limit = 20,
        int offset = 0,
      }) =>
          Future.value([]);

      final c = createContainer(profile: profile);
      await c.read(userProfileProvider.future);

      final repo = c.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryFeed();

      expect(result, isEmpty);
    });

    test('getDiscoveryFeed works with null profile (no interests)', () async {
      final posts = [
        makePost(id: '1', tags: ['flutter'], likesCount: 10),
        makePost(id: '2', tags: ['dart'], likesCount: 20),
      ];

      mockFeedRepo.getFeedStub = ({
        List<String> userInterests = const [],
        int limit = 20,
        int offset = 0,
      }) =>
          Future.value(posts);

      final c = createContainer(profile: null);
      await c.read(userProfileProvider.future);

      final repo = c.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryFeed();

      // With no interests, scoring is only by popularity + recency
      // Post 2 has higher likesCount so it should rank higher
      expect(result.length, 2);
      expect(result[0].id, '2'); // Higher popularity
      expect(result[1].id, '1');
    });

    test('getDiscoveryFeed uses commentsCount × 2 in popularity score',
        () async {
      final profile = Profile(id: 'test-user', interests: []);

      final posts = [
        makePost(id: '1', likesCount: 0, commentsCount: 10),
        makePost(id: '2', likesCount: 15, commentsCount: 0),
      ];

      mockFeedRepo.getFeedStub = ({
        List<String> userInterests = const [],
        int limit = 20,
        int offset = 0,
      }) =>
          Future.value(posts);

      final c = createContainer(profile: profile);
      await c.read(userProfileProvider.future);

      final repo = c.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryFeed();

      // Post 1: popularity = 0 + (10 * 2) = 20 → score = 20 * 0.1 = 2.0
      // Post 2: popularity = 15 + (0 * 2) = 15 → score = 15 * 0.1 = 1.5
      expect(result[0].id, '1');
      expect(result[1].id, '2');
    });

    test('getDiscoveryFeed preserves all post data', () async {
      final profile = Profile(id: 'test-user', interests: ['flutter']);

      final post = makePost(
        id: 'abc',
        tags: ['flutter'],
        likesCount: 5,
        commentsCount: 3,
      );

      mockFeedRepo.getFeedStub = ({
        List<String> userInterests = const [],
        int limit = 20,
        int offset = 0,
      }) =>
          Future.value([post]);

      final c = createContainer(profile: profile);
      await c.read(userProfileProvider.future);

      final repo = c.read(discoveryRepositoryProvider);
      final result = await repo.getDiscoveryFeed();

      expect(result.length, 1);
      expect(result[0].id, 'abc');
      expect(result[0].content, 'Test post abc');
      expect(result[0].tags, ['flutter']);
      expect(result[0].likesCount, 5);
      expect(result[0].commentsCount, 3);
    });
  });
}
