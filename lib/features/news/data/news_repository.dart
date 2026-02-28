import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../../core/services/offline_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../gamification/data/gamification_repository.dart';
import '../domain/news_model.dart';
import 'mesh_news_service.dart';

/// Provider for the [NewsRepository] instance.
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(SupabaseService.client, ref);
});

/// Repository for managing news articles, comments, and upvotes via Supabase and P2P mesh fallback.
class NewsRepository {
  final SupabaseClient _client;
  final Ref _ref;

  /// Creates a [NewsRepository] with a [SupabaseClient] and [Ref].
  NewsRepository(this._client, this._ref);

  /// Adds a comment to a news article.
  ///
  /// [articleId] is the ID of the article to comment on.
  /// [content] is the body of the comment.
  /// [parentId] is optional, used for threading.
  Future<void> addComment(String articleId, String content,
      {String? parentId}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('article_comments').insert({
        'article_id': articleId,
        'user_id': userId,
        'content': content,
        'parent_id': parentId,
      });
    } catch (e) {
      AppLogger.error('Failed to add comment', error: e);
      throw Exception('Could not post comment. Please try again.');
    }
  }

  /// Fetches a single news article by its [articleId].
  Future<NewsArticle> getArticleById(String articleId) async {
    try {
      final response = await _client
          .from('articles')
          .select('*, profiles(*)')
          .eq('id', articleId)
          .single();
      return NewsArticle.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to fetch article by ID', error: e);
      throw Exception('Could not find article.');
    }
  }

  /// Fetches a list of news articles.
  ///
  /// [subject] can be used to filter by category/topic.
  /// [featuredOnly] if true, returns only featured articles.
  ///
  /// Uses a strategy of Supabase -> Cache -> Mesh for resilience.
  Future<List<NewsArticle>> getArticles({
    String? subject,
    bool featuredOnly = false,
  }) async {
    final storage = _ref.read(offlineStorageServiceProvider);
    final meshNews = _ref.read(meshNewsServiceProvider);

    try {
      dynamic query = _client.from('articles').select('*, profiles(*)');

      if (subject != null) {
        query = query.eq('subject', subject);
      }
      if (featuredOnly) {
        query = query.eq('is_featured', true);
      }

      final response = await query
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final articles =
          (response as List).map((json) => NewsArticle.fromJson(json)).toList();

      // OPTIMIZATION: Cache featured articles for offline availability
      if (featuredOnly) {
        storage.cacheData(
            'featured_news_cache', articles.map((a) => a.toJson()).toList());
      }

      // GAIN: Each online fetch broadcasts to mesh neighbors (Gossip propagation)
      for (final article in articles.take(5)) {
        _ref.read(meshNewsServiceProvider.notifier).broadcastArticle(article);
      }

      return articles;
    } catch (e) {
      AppLogger.warning('Supabase fetch failed, falling back to cache/mesh',
          error: e);

      // FALLBACK 1: Local Cache
      if (featuredOnly) {
        final cached = storage.getCachedData('featured_news_cache');
        if (cached != null && cached is List) {
          return cached.map((json) => NewsArticle.fromJson(json)).toList();
        }
      }

      // FALLBACK 2: MESH articles
      return meshNews.where((a) {
        if (subject != null && a.subject != subject) return false;
        if (featuredOnly && !a.isFeatured) return false;
        return true;
      }).toList();
    }
  }

  /// Publishes a new article to Supabase.
  ///
  /// [article] contains the details of the news content.
  Future<void> publishArticle(NewsArticle article) async {
    try {
      await _client.from('articles').insert(article.toJson());
    } catch (e) {
      AppLogger.error('Failed to publish article', error: e);
      throw Exception('Publishing failed. Check your connection.');
    }
  }

  /// Upvotes a specific article.
  ///
  /// [articleId] is the unique identifier of the article.
  Future<void> upvoteArticle(String articleId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('article_upvotes').upsert({
        'user_id': userId,
        'article_id': articleId,
      });

      // Reward XP for engagement
      await _ref.read(gamificationRepositoryProvider).updateXP(5);
    } catch (e) {
      AppLogger.error('Failed to upvote article', error: e);
    }
  }

  /// Vouch for an article's credibility (Sr. Journalist only).
  ///
  /// [articleId] is the article to vouch for.
  /// Throws an exception if the user is not a Senior Journalist or Editor.
  Future<void> vouchArticle(String articleId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // HARDENING: Check if user is Senior Journalist or Editor first
      final profile = await _client
          .from('profiles')
          .select('journalist_level')
          .eq('id', userId)
          .single();
      final level = profile['journalist_level']?.toString().toLowerCase();

      if (level != 'senior' && level != 'editor') {
        throw Exception(
            'Only Senior Journalists or Editors can vouch for articles.');
      }

      await _client.from('article_upvotes').upsert({
        'user_id': userId,
        'article_id': articleId,
        'vote_weight': 2, // Vouch counts double
      });
    } catch (e) {
      AppLogger.error('Failed to vouch for article', error: e);
      rethrow;
    }
  }

  /// Streams articles for real-time updates.
  Stream<List<NewsArticle>> watchArticles(
      {String? subject, bool featuredOnly = false}) {
    dynamic query = _client.from('articles').stream(primaryKey: ['id']);
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    if (featuredOnly) {
      query = query.eq('is_featured', true);
    }
    return query.order('created_at', ascending: false).map((data) =>
        (data as List).map((json) => NewsArticle.fromJson(json)).toList());
  }
}
