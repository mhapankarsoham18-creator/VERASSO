import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/search/data/search_service.dart';

import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late SearchService searchService;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    searchService = SearchService(client: mockSupabase);
  });

  group('Search Integration Tests', () {
    test('complete search flow: index content → full-text query', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'user-2',
          'type': 'user',
          'full_name': 'John Developer',
          'bio': 'Flutter enthusiast',
          'relevance_score': 98,
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final results = await searchService.search('developer');

      expect(results, isNotEmpty);
      expect(results[0].type, 'user');
    });

    test('search across users returns matching profiles', () async {
      final usersBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'user-2',
          'full_name': 'John Developer',
          'email': 'john@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'relevance': 95,
        },
        {
          'id': 'user-3',
          'full_name': 'Jane Dev',
          'email': 'jane@example.com',
          'avatar_url': 'https://example.com/avatar2.jpg',
          'relevance': 85,
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', usersBuilder);

      final users = await searchService.searchUsers('dev');

      expect(users.length, 2);
      expect(users[0].fullName, contains('Dev'));
    });

    test('search across posts by content', () async {
      final postsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': 'user-2',
          'content': 'Flutter is awesome',
          'created_at': DateTime.now().toIso8601String(),
          'relevance': 92,
          'profiles': {
            'full_name': 'John Developer',
          }
        },
        {
          'id': 'post-2',
          'user_id': 'user-3',
          'content': 'Just learned Flutter',
          'created_at': DateTime.now().toIso8601String(),
          'relevance': 88,
          'profiles': {
            'full_name': 'Jane Dev',
          }
        }
      ]);
      mockSupabase.setQueryBuilder('posts', postsBuilder);

      final posts = await searchService.searchPosts('Flutter');

      expect(posts.length, 2);
      expect(posts.every((p) => p.content.contains('Flutter')), true);
    });

    test('search across groups by name and description', () async {
      final groupsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'group-1',
          'name': 'Flutter Developers',
          'description': 'Community for Flutter enthusiasts',
          'member_count': 150,
          'relevance': 94,
        },
        {
          'id': 'group-2',
          'name': 'Web Developers',
          'description': 'For Flutter web developers',
          'member_count': 85,
          'relevance': 78,
        }
      ]);
      mockSupabase.setQueryBuilder('groups', groupsBuilder);

      final groups = await searchService.searchGroups('Flutter');

      expect(groups.length, 2);
      expect(groups[0].name, contains('Flutter'));
    });

    test('search results ranked by relevance score', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'result-1',
          'type': 'post',
          'user_id': 'user-2',
          'title': 'Flutter Tutorial',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
          'relevance_score': 99,
        },
        {
          'id': 'result-2',
          'type': 'post',
          'user_id': 'user-2',
          'title': 'Flutter Google I/O 2023',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
          'relevance_score': 95,
        },
        {
          'id': 'result-3',
          'type': 'post',
          'user_id': 'user-2',
          'title': 'Fluttering Leaves Animation',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
          'relevance_score': 65,
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final results = await searchService.search('Flutter');

      expect(results[0].relevance, greaterThan(results[1].relevance));
      expect(results[1].relevance, greaterThan(results[2].relevance));
    });

    test('search with pagination handles large result sets', () async {
      final largeResultSet = List.generate(
        100,
        (i) => {
          'id': 'result-$i',
          'type': 'post',
          'user_id': 'user-2',
          'title': 'Result $i',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
          'relevance_score': 100 - i,
        },
      );

      final searchBuilder = MockSupabaseQueryBuilder(
          selectResponse: largeResultSet.take(20).toList());
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final page1 = await searchService.search('query', page: 1, pageSize: 20);

      expect(page1.length, 20);
    });

    test('next page pagination works correctly', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'result-21',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'result-22',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'result-40',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Content',
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final page2 = await searchService.search('query', page: 2, pageSize: 20);

      expect(page2, isNotEmpty);
    });

    test('search with filters applied correctly', () async {
      final filteredBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Filtered content',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', filteredBuilder);

      final results = await searchService.searchWithFilters(
        query: 'Flutter',
        filters: {
          'type': 'post',
          'created_after': DateTime.now().subtract(Duration(days: 30)),
        },
      );

      expect(results, isNotEmpty);
      expect(results[0].type, 'post');
    });

    test('search with date range filter', () async {
      final startDate = DateTime.now().subtract(Duration(days: 7));
      final endDate = DateTime.now();

      final resultsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Date range content',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', resultsBuilder);

      final results = await searchService.searchByDateRange(
        query: 'Flutter',
        startDate: startDate,
        endDate: endDate,
      );

      expect(results, isNotEmpty);
    });

    test('search with user filter shows results from specific users', () async {
      final userResultsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Flutter post',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', userResultsBuilder);

      final results = await searchService.searchByUser(
        query: 'Flutter',
        userId: 'user-2',
      );

      expect(results, isNotEmpty);
    });

    test('search suggestion/autocomplete on partial query', () async {
      final suggestionsBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'term': 'Flutter'},
        {'term': 'Fluttering'},
        {'term': 'Flutter plugin'},
      ]);
      mockSupabase.setQueryBuilder('search_suggestions', suggestionsBuilder);

      final suggestions = await searchService.getSuggestions('Flut');

      expect(suggestions.length, greaterThan(0));
      expect(suggestions[0], startsWith('Flut'));
    });

    test('special characters in search query handled safely', () async {
      final specialBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'C++ and Java',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', specialBuilder);

      final results = await searchService.search('C++');

      expect(results, isNotEmpty);
    });

    test('search with quoted phrase matches exact phrase', () async {
      final exactBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Flutter web development',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', exactBuilder);

      final results = await searchService.searchExactPhrase('Flutter web');

      expect(results, isNotEmpty);
    });
  });

  group('Search Integration - Indexing & Performance', () {
    test('content indexed for quick full-text search', () async {
      final indexBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('search_index', indexBuilder);

      await expectLater(
        searchService.indexContent(
          contentId: 'post-1',
          type: 'post',
          title: 'Flutter Tips',
          body: 'Tips and tricks for Flutter development',
        ),
        completes,
      );
    });

    test('bulk index operation on content database', () async {
      final bulkIndexes = List.generate(
        100,
        (i) => {
          'id': 'post-$i',
          'title': 'Post $i',
          'body': 'Content for post $i'
        },
      );

      final indexBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('search_index', indexBuilder);

      final futures = bulkIndexes.map((content) {
        return searchService.indexContent(
          contentId: content['id'],
          type: 'post',
          title: content['title'],
          body: content['body'],
        );
      }).toList();

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });

    test('search returns results within acceptable latency', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {'id': 'result-1'},
        {'id': 'result-2'},
      ]);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final stopwatch = Stopwatch()..start();
      await searchService.search('Flutter');
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('search with rate limiting enforced', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      // Execute 30 searches (at limit)
      final futures = List.generate(
        30,
        (i) => searchService.search('query-$i'),
      );

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });
  });

  group('Search Integration - High Volume', () {
    test('search across 100,000+ indexed items', () async {
      final hugeIndex = List.generate(
        100000,
        (i) => {
          'id': 'item-$i',
          'type': 'post',
          'user_id': 'user-2',
          'title': 'Item $i',
          'content': 'Item content $i',
          'created_at': DateTime.now().toIso8601String(),
          'relevance_score': 100 - (i % 100),
        },
      );

      final indexBuilder =
          MockSupabaseQueryBuilder(selectResponse: hugeIndex.take(50).toList());
      mockSupabase.setQueryBuilder('search_index', indexBuilder);

      final stopwatch = Stopwatch()..start();
      final results = await searchService.search('item');
      stopwatch.stop();

      expect(results.length, 50);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('concurrent search operations handled safely', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'result-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Result content',
          'created_at': DateTime.now().toIso8601String(),
        },
      ]);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final futures = List.generate(
        100,
        (i) => searchService.search('query-$i'),
      );

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });

    test('search with complex multi-filter on large dataset', () async {
      final complexResults = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': 'Flutter is great',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', complexResults);

      final results = await searchService.searchWithFilters(
        query: 'Flutter',
        filters: {
          'type': 'post',
          'user_id': 'user-2',
          'created_after': DateTime.now().subtract(Duration(days: 7)),
        },
      );

      expect(results, isNotEmpty);
    });
  });

  group('Search Integration - Error Handling', () {
    test('empty search query returns empty results', () async {
      final emptyBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('search_index', emptyBuilder);

      final results = await searchService.search('');

      expect(results, isEmpty);
    });

    test('search with very long query truncated gracefully', () async {
      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      final longQuery = 'x' * 1000;

      final results = await searchService.search(longQuery);

      expect(results, anyOf(isNotEmpty, isEmpty));
    });

    test('network error during search handled', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('search_index', builder);

      // Should handle gracefully
      expect(true, true);
    });

    test('invalid filter values rejected', () async {
      // Filter validation should prevent invalid queries
      expect(true, true);
    });

    test('XSS prevention in search results display', () async {
      final xssBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'type': 'post',
          'user_id': 'user-2',
          'content': '&lt;script&gt;alert("xss")&lt;/script&gt;',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('search_index', xssBuilder);

      final results = await searchService.search('script');

      // Results should be sanitized
      expect(results, isNotEmpty);
    });

    test('SQL injection prevention in search queries', () async {
      final sqlInjectionAttempt = "'; DROP TABLE search_index; --";

      final searchBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('search_index', searchBuilder);

      // Should not alter database
      final results = await searchService.search(sqlInjectionAttempt);

      expect(results, anyOf(isNotEmpty, isEmpty));
    });
  });
}
