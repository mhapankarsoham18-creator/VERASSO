import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/supabase_service.dart';
import '../models/search_results.dart';

/// Provider for the [SearchService] instance.
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

/// Service that performs simple ILIKE searches against Supabase tables.
class SearchService {
  final SupabaseClient _client;

  /// Creates a [SearchService] with an optional [SupabaseClient].
  SearchService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Get search suggestions.
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client
          .from('search_suggestions')
          .select('term')
          .ilike('term', '$query%')
          .limit(10);
      return (response as List).map((e) => e['term'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Indexes content for search.
  Future<void> indexContent({
    String? contentId,
    String? type,
    String? title,
    String? body,
    String? table,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('search_index').upsert({
        'content_id': contentId,
        'type': type,
        'title': title,
        'body': body,
        'table_name': table,
        'metadata': metadata,
        'indexed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Failed to index content', error: e);
    }
  }

  /// Generic search method that hits the unified search index.
  Future<SearchResults> search(String query, {int? page, int? pageSize}) async {
    if (query.trim().isEmpty) {
      return SearchResults(users: [], posts: [], groups: []);
    }
    try {
      var queryBuilder = _client.from('search_index').select();
      queryBuilder = queryBuilder.ilike('title', '%$query%');

      if (page != null && pageSize != null) {
        final from = (page - 1) * pageSize;
        final to = from + pageSize - 1;
        final response = await queryBuilder.range(from, to);
        return _mapResults(response as List);
      }

      final response = await queryBuilder;
      return _mapResults(response as List);
    } catch (e) {
      return searchAll(query); // Fallback to categorical search
    }
  }

  /// Search all categories
  Future<SearchResults> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return SearchResults(users: [], posts: [], groups: []);
    }

    try {
      final results = await Future.wait([
        searchUsers(query),
        searchPosts(query),
        searchGroups(query),
      ]);

      return SearchResults(
        users: results[0] as List<UserSearchResult>,
        posts: results[1] as List<PostSearchResult>,
        groups: results[2] as List<GroupSearchResult>,
      );
    } catch (e) {
      AppLogger.info('Search all error: $e');
      throw DatabaseException('Search failed', null, e);
    }
  }

  /// Search by date range.
  Future<SearchResults> searchByDateRange(
      {required String query, DateTime? startDate, DateTime? endDate}) async {
    try {
      var queryBuilder = _client.from('search_index').select();
      queryBuilder = queryBuilder.ilike('title', '%$query%');
      if (startDate != null) {
        queryBuilder =
            queryBuilder.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        queryBuilder =
            queryBuilder.lte('created_at', endDate.toIso8601String());
      }
      final response = await queryBuilder;
      return _mapResults(response as List);
    } catch (e) {
      return search(query);
    }
  }

  /// Search by user.
  Future<SearchResults> searchByUser(
      {required String query, String? userId}) async {
    try {
      var queryBuilder = _client.from('search_index').select();
      queryBuilder = queryBuilder.ilike('title', '%$query%');
      if (userId != null) {
        queryBuilder = queryBuilder.eq('user_id', userId);
      }
      final response = await queryBuilder;
      return _mapResults(response as List);
    } catch (e) {
      return search(query);
    }
  }

  /// Search exact phrase.
  Future<SearchResults> searchExactPhrase(String phrase) async {
    try {
      final response = await _client
          .from('search_index')
          .select()
          .textSearch('title', phrase, config: 'english');
      return _mapResults(response as List);
    } catch (e) {
      return search(phrase);
    }
  }

  /// Search groups by name or description
  Future<List<GroupSearchResult>> searchGroups(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('groups')
          .select('id, name, description, avatar_url, member_count')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((e) => GroupSearchResult.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.info('Search groups error: $e');
      throw DatabaseException('Failed to search groups', null, e);
    }
  }

  /// Search posts by content or tags
  Future<List<PostSearchResult>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('posts')
          .select(
              'id, user_id, content, created_at, profiles:user_id(full_name, avatar_url)')
          .filter('deleted_at', 'is', null)
          .or('content.ilike.%$query%,tags.cs.{$query}')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((e) => PostSearchResult.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.info('Search posts error: $e');
      throw DatabaseException('Failed to search posts', null, e);
    }
  }

  /// Search users by name or username
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, avatar_url, bio')
          .or('full_name.ilike.%$query%,username.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((e) => UserSearchResult.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.info('Search users error: $e');
      throw DatabaseException('Failed to search users', null, e);
    }
  }

  /// Search with filters.
  Future<SearchResults> searchWithFilters(
          {required String query,
          Map<String, dynamic>? filters,
          int? page,
          int? pageSize}) =>
      search(query, page: page, pageSize: pageSize);

  SearchResults _mapResults(List results) {
    final users = <UserSearchResult>[];
    final posts = <PostSearchResult>[];
    final groups = <GroupSearchResult>[];

    for (final item in results) {
      final type = item['type'] as String?;
      if (type == 'user') {
        users.add(UserSearchResult.fromJson(item));
      } else if (type == 'post') {
        posts.add(PostSearchResult.fromJson(item));
      } else if (type == 'group') {
        groups.add(GroupSearchResult.fromJson(item));
      }
    }
    return SearchResults(users: users, posts: posts, groups: groups);
  }
}
