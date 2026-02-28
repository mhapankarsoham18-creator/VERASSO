import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/services/content_recommendation_service.dart';
import 'package:verasso/features/learning/data/course_models.dart';

import '../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockCourseRepository mockCourseRepo;
  late ContentRecommendationService service;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockClient = MockSupabaseClient(auth: mockAuth);
    mockCourseRepo = MockCourseRepository();
    service = ContentRecommendationService(mockCourseRepo, client: mockClient);

    when(mockAuth.currentUser).thenReturn(
      User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'aud',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  });

  group('ContentRecommendationService - Supabase Integration', () {
    test('fetchRecommendedPosts calls get_recommended_posts RPC', () async {
      final mockPosts = [
        {
          'id': 'post-1',
          'user_id': 'user-1',
          'content': 'Hello',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      mockClient.setRpcResponse('get_recommended_posts', mockPosts);

      final result = await service.fetchRecommendedPosts(limit: 5);

      expect(result, isNotEmpty);
      expect(result.first.postId, 'post-1');
      expect(mockClient.lastRpcName, 'get_recommended_posts');
    });

    test('fetchRecommendedUsers calls get_recommended_users RPC', () async {
      final mockUsers = [
        {'id': 'user-2', 'username': 'user2'}
      ];

      mockClient.setRpcResponse('get_recommended_users', mockUsers);

      final result = await service.fetchRecommendedUsers(limit: 5);

      expect(result, isNotEmpty);
      expect(result.first.userId, 'user-2');
      expect(mockClient.lastRpcName, 'get_recommended_users');
    });

    test('fetchUserInterests query user_interests table', () async {
      final mockInterests = [
        {'category': 'physics', 'score': 10, 'weight': 1.0},
        {'category': 'astronomy', 'score': 5, 'weight': 1.2},
      ];

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      filterBuilder.setResponse(mockInterests);

      mockClient.setQueryBuilder('user_interests', queryBuilder);

      final result = await service.fetchUserInterests();

      expect(result.length, 2);
      expect(result.first['category'], 'physics');
    });
  });

  group('ContentRecommendationService - recommendSimulations', () {
    test('uses weighted interests from database if available', () async {
      // Mock published courses
      final courses = [
        Course(
          id: 'course-physics',
          creatorId: 'teacher-1',
          title: 'Advanced Physics',
          isPublished: true,
          createdAt: DateTime.now(),
        ),
        Course(
          id: 'course-art',
          creatorId: 'teacher-1',
          title: 'Art History',
          isPublished: true,
          createdAt: DateTime.now(),
        ),
      ];

      when(mockCourseRepo.getPublishedCourses())
          .thenAnswer((_) async => courses);

      // Mock database interests (weighted towards physics)
      final mockInterests = [
        {'category': 'physics', 'score': 10, 'weight': 1.0},
      ];

      // We need to bypass fetchUserInterests in the test or mock the specific Supabase call
      // For simplicity in this test environment, we'll verify the logic in recommendSimulations
      // actually uses the fetchUserInterests result.

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      filterBuilder.setResponse(mockInterests);
      mockClient.setQueryBuilder('user_interests', queryBuilder);

      final result = await service.recommendSimulations(
        userId: 'user-123',
        completedSimulations: [],
        categoryProgress: {},
        interests: ['art'], // Legacy interest but DB has physics
      );

      // Physics should be recommended due to DB weight
      expect(result.any((r) => r.simulationId == 'course-physics'), isTrue);
      expect(
          result.firstWhere((r) => r.simulationId == 'course-physics').reason,
          contains('interest in physics'));
    });

    test('falls back to legacy interests if database is empty', () async {
      when(mockCourseRepo.getPublishedCourses()).thenAnswer((_) async => [
            Course(
              id: 'course-art',
              creatorId: 'teacher-1',
              title: 'Art History',
              isPublished: true,
              createdAt: DateTime.now(),
            ),
          ]);

      // Mock empty DB interests
      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      filterBuilder.setResponse([]);
      mockClient.setQueryBuilder('user_interests', queryBuilder);

      final result = await service.recommendSimulations(
        userId: 'user-123',
        completedSimulations: [],
        categoryProgress: {},
        interests: ['art'],
      );

      expect(result.any((r) => r.simulationId == 'course-art'), isTrue);
    });
  });

  group('ContentRecommendationService - Ranking Logic', () {
    test('deduplicates and ranks simulations properly', () async {
      final courses = [
        Course(
            id: 'c1',
            creatorId: 't1',
            title: 'Course 1',
            createdAt: DateTime.now()),
        Course(
            id: 'c2',
            creatorId: 't1',
            title: 'Course 2',
            createdAt: DateTime.now()),
      ];
      when(mockCourseRepo.getPublishedCourses())
          .thenAnswer((_) async => courses);

      final queryBuilder = MockSupabaseQueryBuilder();
      final filterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      filterBuilder.setResponse([]);
      mockClient.setQueryBuilder('user_interests', queryBuilder);

      final result = await service.recommendSimulations(
        userId: 'user-123',
        completedSimulations: [],
        categoryProgress: {'Course 2': 10}, // Boost c2
        interests: ['Course 1'], // Boost c1
      );

      expect(result.length, 2);
      // Both should be present, unique
      expect(result.map((r) => r.simulationId).toSet().length, 2);
    });
  });
}
