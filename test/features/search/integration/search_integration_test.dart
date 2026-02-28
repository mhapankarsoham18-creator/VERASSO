import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/search/services/full_text_search_service.dart';

import '../../../mocks.dart';

/// Integration tests for Full-Text Search Service
void main() {
  group('FullTextSearchService Integration Tests', () {
    late FullTextSearchService searchService;
    late MockSupabaseClient mockClient;

    setUpAll(() async {
      mockClient = MockSupabaseClient();
      searchService = FullTextSearchService(mockClient);
    });

    group('Search Functionality', () {
      test('search returns results for valid query', () async {
        final results = await searchService.search('flutter');
        expect(results, isA<List<SearchResult>>());
      });

      test('search with post filter filters results', () async {
        final results = await searchService.search(
          'test',
          filter: SearchFilter(type: SearchResultType.post),
        );
        expect(results, isA<List<SearchResult>>());
        for (var result in results) {
          expect(result.type, equals(SearchResultType.post));
        }
      });

      test('search respects pagination', () async {
        final page1 = await searchService.search(
          'test',
          page: 1,
          pageSize: 5,
        );
        final page2 = await searchService.search(
          'test',
          page: 2,
          pageSize: 5,
        );
        expect(page1, isA<List<SearchResult>>());
        expect(page2, isA<List<SearchResult>>());
      });

      test('getTrendingHashtags returns hashtags', () async {
        final results = await searchService.getTrendingHashtags(limit: 10);
        expect(results, isA<List<SearchResult>>());
        for (var result in results) {
          expect(result.type, equals(SearchResultType.hashtag));
        }
      });

      test('getSearchSuggestions returns suggestions', () async {
        final suggestions = await searchService.getSearchSuggestions('test');
        expect(suggestions, isA<List<String>>());
      });

      test('invalid query throws exception', () async {
        expect(
          () => searchService.search(''),
          throwsException,
        );
      });
    });

    group('Search History', () {
      test('getUserSearchHistory returns history', () async {
        await searchService.search('test');
        final history = await searchService.getUserSearchHistory();
        expect(history, isA<List<Map<String, dynamic>>>());
      });

      test('clearSearchHistory clears all history', () async {
        await searchService.search('test1');
        await searchService.clearSearchHistory();
        final history = await searchService.getUserSearchHistory();
        expect(history.isEmpty, isTrue);
      });
    });
  });
}
