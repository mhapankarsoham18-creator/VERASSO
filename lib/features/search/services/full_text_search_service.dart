import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Riverpod providers
/// Provider for the [FullTextSearchService] instance.
final fullTextSearchServiceProvider = Provider((ref) {
  return FullTextSearchService(Supabase.instance.client);
});

/// Provider for user search history.
final searchHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(fullTextSearchServiceProvider);
  return service.getUserSearchHistory();
});

/// Family provider for searching with a query and filters.
final searchResultsProvider =
    FutureProvider.family<List<SearchResult>, (String, SearchFilter?)>(
  (ref, params) async {
    final service = ref.read(fullTextSearchServiceProvider);
    return service.search(params.$1, filter: params.$2);
  },
);

/// Family provider for search suggestions.
final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  final service = ref.read(fullTextSearchServiceProvider);
  return service.getSearchSuggestions(query);
});

/// Provider for trending hashtags.
final trendingHashtagsProvider =
    FutureProvider<List<SearchResult>>((ref) async {
  final service = ref.read(fullTextSearchServiceProvider);
  return service.getTrendingHashtags();
});

/// Full-Text Search Service
/// Advanced search service providing full-text search capabilities across posts, users, and hashtags.
class FullTextSearchService {
  final SupabaseClient _client;

  /// Creates a [FullTextSearchService] instance.
  FullTextSearchService(this._client);

  /// Clear user's search history
  Future<void> clearSearchHistory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('search_history').delete().eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('Clear search history error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to clear search history');
    }
  }

  /// Delete specific search history item
  Future<void> deleteSearchHistoryItem(String id) async {
    try {
      await _client.from('search_history').delete().eq('id', id);
    } catch (e, stack) {
      AppLogger.error('Delete search history item error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to delete search item');
    }
  }

  /// Get search suggestions/autocomplete
  Future<List<String>> getSearchSuggestions(String query,
      {int limit = 5}) async {
    try {
      if (query.isEmpty || query.length > 50) return [];

      // Get matching hashtags
      final hashtagResponse = await _client
          .from('hashtags')
          .select('hashtag')
          .ilike('hashtag', '%${query.replaceAll('#', '')}%')
          .order('usage_count', ascending: false)
          .limit(limit);

      final suggestions = <String>[];

      for (var item in hashtagResponse as List) {
        suggestions.add('#${item['hashtag']}');
      }

      return suggestions;
    } catch (e, stack) {
      AppLogger.error('Get suggestions error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Get trending hashtags
  Future<List<SearchResult>> getTrendingHashtags({int limit = 10}) async {
    try {
      final response = await _client
          .from('hashtags')
          .select('hashtag, usage_count, trending_score, created_at')
          .order('trending_score', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) =>
              SearchResult.fromHashtagJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Get trending hashtags error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Get user's search history
  Future<List<Map<String, dynamic>>> getUserSearchHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('search_history')
          .select('id, query, result_type, results_count, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('Get search history error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Search posts, users, and hashtags
  Future<List<SearchResult>> search(
    String query, {
    SearchFilter? filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Validate query length (prevent DoS)
      if (query.isEmpty || query.length > 500) {
        throw Exception('Search query must be 1-500 characters');
      }

      // Sanitize and normalize query
      final sanitizedQuery = _sanitizeQuery(query);

      // Check for blocked search terms (security)
      if (await _isBlockedSearchTerm(sanitizedQuery)) {
        throw Exception('This search term is not allowed');
      }

      // Record search history (async, non-blocking)
      _recordSearchHistory(sanitizedQuery, filter?.type);

      final results = <SearchResult>[];
      final offset = (page - 1) * pageSize;

      // Build dynamic query based on filter type
      if (filter?.type == null || filter?.type == SearchResultType.post) {
        final postResults = await _searchPosts(
          sanitizedQuery,
          filter,
          pageSize,
          offset,
        );
        results.addAll(postResults);
      }

      if (filter?.type == null || filter?.type == SearchResultType.user) {
        final userResults = await _searchUsers(
          sanitizedQuery,
          filter,
          pageSize,
          offset,
        );
        results.addAll(userResults);
      }

      if (filter?.type == null || filter?.type == SearchResultType.hashtag) {
        final hashtagResults = await _searchHashtags(
          sanitizedQuery,
          filter,
          pageSize,
          offset,
        );
        results.addAll(hashtagResults);
      }

      // Sort by relevance score if mixed results
      if (filter?.type == null) {
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      }

      return results.take(pageSize).toList();
    } catch (e, stack) {
      AppLogger.error('Full-text search error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check if search term is blocked
  Future<bool> _isBlockedSearchTerm(String query) async {
    try {
      final response = await _client
          .from('blocked_search_terms')
          .select('id')
          .eq('term', query)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      AppLogger.info('Check blocked search term error: $e');
      return false;
    }
  }

  /// Record search in history (fire and forget)
  void _recordSearchHistory(String query, SearchResultType? type) {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Non-blocking insert
      _client.from('search_history').insert({
        'user_id': userId,
        'query': query,
        'result_type': type?.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      }).then(
        (_) => AppLogger.info('Search history recorded'),
        onError: (e) => AppLogger.info('Record search history error: $e'),
      );
    } catch (e) {
      AppLogger.info('Record search history error: $e');
    }
  }

  /// Sanitize search query to prevent injection attacks
  String _sanitizeQuery(String query) {
    // Remove dangerous characters
    return query.replaceAll(RegExp(r'[^\w\s#@-]'), '').trim();
  }

  /// Search hashtags
  Future<List<SearchResult>> _searchHashtags(
    String query,
    SearchFilter? filter,
    int limit,
    int offset,
  ) async {
    try {
      var request = _client.from('hashtags').select(
          'hashtag, usage_count, trending_score, last_used_at, created_at');

      // Normalize hashtag query
      final hashtagQuery = query.startsWith('#') ? query.substring(1) : query;

      request = request.ilike('hashtag', '%$hashtagQuery%');

      // Sort by trending or usage
      var sortedRequest = request.order('trending_score', ascending: false);

      final paginatedRequest = sortedRequest.range(offset, offset + limit - 1);

      final response = await paginatedRequest;

      return (response as List)
          .map((json) =>
              SearchResult.fromHashtagJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.info('Search hashtags error: $e');
      return [];
    }
  }

  /// Search posts with full-text search
  Future<List<SearchResult>> _searchPosts(
    String query,
    SearchFilter? filter,
    int limit,
    int offset,
  ) async {
    try {
      var request = _client.from('posts').select(
          'id, title, content, featured_image_url, created_at, views, likes');

      // Apply text search using PostgreSQL full-text search
      request = request.or('title.ilike.%$query%,content.ilike.%$query%');

      // Apply filters
      if (filter?.userId != null) {
        request = request.eq('user_id', filter!.userId!);
      }

      if (filter?.dateFrom != null) {
        request =
            request.gte('created_at', filter!.dateFrom!.toIso8601String());
      }

      if (filter?.dateTo != null) {
        request = request.lte('created_at', filter!.dateTo!.toIso8601String());
      }

      if (filter?.minViews != null) {
        request = request.gte('views', filter!.minViews!);
      }

      // Apply sorting
      final sortOrder = filter?.sortByRecent ?? false ? 'desc' : 'asc';
      var sortedRequest =
          request.order('created_at', ascending: sortOrder == 'asc');

      final paginatedRequest = sortedRequest.range(offset, offset + limit - 1);

      final response = await paginatedRequest;

      return (response as List)
          .map(
              (json) => SearchResult.fromPostJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.info('Search posts error: $e');
      return [];
    }
  }

  /// Search users
  Future<List<SearchResult>> _searchUsers(
    String query,
    SearchFilter? filter,
    int limit,
    int offset,
  ) async {
    try {
      var request = _client
          .from('users')
          .select('id, username, bio, avatar_url, created_at');

      // Case-insensitive username search
      request = request.or('username.ilike.%$query%,bio.ilike.%$query%');

      final paginatedRequest = request.range(offset, offset + limit - 1);

      final response = await paginatedRequest;

      return (response as List)
          .map(
              (json) => SearchResult.fromUserJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.info('Search users error: $e');
      return [];
    }
  }
}

/// Search filter options
/// Options for filtering and sorting search results.
class SearchFilter {
  /// Filter by a specific result type.
  final SearchResultType? type;

  /// Filter results created after this date.
  final DateTime? dateFrom;

  /// Filter results created before this date.
  final DateTime? dateTo;

  /// Filter results with at least this many views.
  final int? minViews;

  /// Filter results created by this specific user.
  final String? userId;

  /// Whether to sort results by most recent first.
  final bool sortByRecent;

  /// Creates a [SearchFilter] with specified options.
  SearchFilter({
    this.type,
    this.dateFrom,
    this.dateTo,
    this.minViews,
    this.userId,
    this.sortByRecent = false,
  });
}

/// Model for search results
/// Detailed model for multi-category search results.
class SearchResult {
  /// Unique identifier for the search result item.
  final String id;

  /// The category type of the result.
  final SearchResultType type;

  /// The primary title or name of the result.
  final String title;

  /// A brief description or bio.
  final String subtitle;

  /// URL to an associated image (featured image or avatar).
  final String? imageUrl;

  /// The calculated relevance score for sorting.
  final double relevanceScore;

  /// The date when the item was created.
  final DateTime createdAt;

  /// Optional view count.
  final int? views;

  /// Optional like count.
  final int? likes;

  /// Creates a [SearchResult].
  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.relevanceScore,
    required this.createdAt,
    this.views,
    this.likes,
  });

  /// Creates a [SearchResult] from a hashtag JSON map.
  factory SearchResult.fromHashtagJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['hashtag'] ?? '',
      type: SearchResultType.hashtag,
      title: json['hashtag'] ?? '#unknown',
      subtitle: '${json['usage_count'] ?? 0} posts',
      relevanceScore: (json['trending_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      views: json['usage_count'] as int?,
    );
  }

  /// Creates a [SearchResult] from a post JSON map.
  factory SearchResult.fromPostJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? '',
      type: SearchResultType.post,
      title: json['title'] ?? 'Untitled Post',
      subtitle: json['content'] ?? '',
      imageUrl: json['featured_image_url'],
      relevanceScore: 0.0, // Calculated separately
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      views: json['views'] as int?,
      likes: json['likes'] as int?,
    );
  }

  /// Creates a [SearchResult] from a user JSON map.
  factory SearchResult.fromUserJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? '',
      type: SearchResultType.user,
      title: json['full_name'] ?? json['username'] ?? 'Anonymous',
      subtitle: json['bio'] ?? '',
      imageUrl: json['avatar_url'],
      relevanceScore: 0.0, // Calculated separately
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Search result types
enum SearchResultType {
  /// Represents a post.
  post,

  /// Represents a user profile.
  user,

  /// Represents a hashtag.
  hashtag,
}
