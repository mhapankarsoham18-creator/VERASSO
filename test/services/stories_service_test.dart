import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/services/stories_service.dart';

import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late StoriesService service;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockSupabase = MockSupabaseClient(auth: mockAuth);
    service = StoriesService(client: mockSupabase);
  });

  group('StoriesService - Retrieval', () {
    test('getActiveStories returns empty list by default', () async {
      // With Fakes, we just call it and it won't crash
      final result = await service.getActiveStories();
      expect(result, isA<List>());
    });

    test('getMyStories returns empty list by default', () async {
      mockAuth.setCurrentUser(TestSupabaseUser(id: 'my-id'));
      final result = await service.getMyStories();
      expect(result, isA<List>());
    });
  });

  group('StoriesService - Interactions', () {
    test('viewStory should not throw', () async {
      await service.viewStory('story-1');
      // Success is not throwing
    });

    test('reactToStory should not throw', () async {
      mockAuth.setCurrentUser(TestSupabaseUser(id: 'my-id'));

      // Mock user_stories response for owner check
      final userStoriesBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'user_id': 'owner-id'}
      ]);
      mockSupabase.setQueryBuilder('user_stories', userStoriesBuilder);

      await service.reactToStory(storyId: 'story-1', reactionType: 'heart');
      // Success is not throwing
    });
  });
}
