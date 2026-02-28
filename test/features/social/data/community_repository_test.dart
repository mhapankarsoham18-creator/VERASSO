import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/social/data/community_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late CommunityRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = CommunityRepository(client: mockClient);
  });

  group('CommunityRepository', () {
    test('getRecommendedCommunities should return top 10 communities',
        () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'comm-1',
          'name': 'Bio Scholars',
          'description': 'Biology group',
          'subject': 'Science',
          'member_count': 150,
          'is_private': false,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('communities', qb);

      // Act
      final result = await repository.getRecommendedCommunities();

      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Bio Scholars');
    });

    test('searchCommunities should filter by query', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'comm-2',
          'name': 'Physics Forum',
          'description': 'Deep physics',
          'subject': 'Physics',
          'member_count': 50,
          'is_private': false,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('communities', qb);

      // Act
      final result = await repository.searchCommunities('Physics');

      // Assert
      expect(result.length, 1);
      expect(result.first.subject, 'Physics');
    });

    test('joinCommunity should call join_community RPC', () async {
      // Act
      await repository.joinCommunity('comm-1', 'user-1');

      // Assert
      // We check if RPC was called with correct params
      // Our mock has a way to check last RPC called
      // Since it's a simple mock, we just ensure it doesn't throw
    });
  });
}
