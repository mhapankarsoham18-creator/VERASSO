import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/news/data/news_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late NewsService newsService;

  setUp(() {
    mockClient = MockSupabaseClient();
    newsService = NewsServiceImpl(client: mockClient);
  });

  group('NewsService', () {
    test('fetchNews should return articles sorted by importance', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'news-1',
          'author_id': 'user-1',
          'title': 'High Importance News',
          'importance': 5,
          'category': 'science',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'news-2',
          'author_id': 'user-2',
          'title': 'Low Importance News',
          'importance': 1,
          'category': 'science',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('news', qb);

      // Act
      final result = await newsService.fetchNews(category: 'science');

      // Assert
      expect(result.length, 2);
      expect(result.first.importance, 5);
      expect(result.last.importance, 1);
    });

    test('fetchHistoricalEvents should filter by history category', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'hist-1',
          'author_id': 'user-1',
          'title': 'Ancient History',
          'category': 'history',
          'importance': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('news', qb);

      // Act
      final result = await newsService.fetchHistoricalEvents();

      // Assert
      expect(result.length, 1);
      expect(result.first.title, 'Ancient History');
    });

    test('fetchFeaturedNews should filter by is_featured', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'feat-1',
          'author_id': 'user-1',
          'title': 'Breaking News',
          'is_featured': true,
          'importance': 4,
          'category': 'world',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('news', qb);

      // Act
      final result = await newsService.fetchFeaturedNews();

      // Assert
      expect(result.length, 1);
      expect(result.first.isFeatured, true);
    });
  });
}
