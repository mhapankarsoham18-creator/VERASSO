import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

import '../domain/news_model.dart';

/// Provider for the [NewsService] instance.
final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsServiceImpl();
});

/// Interface for fetching external and historical news articles.
abstract class NewsService {
  /// Fetches featured news articles.
  Future<List<NewsArticle>> fetchFeaturedNews();

  /// Fetches historical events.
  Future<List<NewsArticle>> fetchHistoricalEvents();

  /// Fetches news by category.
  Future<List<NewsArticle>> fetchNews({required String category});
}

/// Implementation of [NewsService] using Supabase.
class NewsServiceImpl implements NewsService {
  final SupabaseClient _client;

  /// Creates a [NewsServiceImpl] with an optional [client].
  NewsServiceImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  @override
  Future<List<NewsArticle>> fetchFeaturedNews() async {
    try {
      final response = await _client
          .from('news')
          .select(
              '*, profiles:author_id(full_name, avatar_url, journalist_level)')
          .eq('is_featured', true)
          .eq('is_published', true)
          .order('importance', ascending: false)
          .limit(5);

      return (response as List).map((e) => NewsArticle.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Featured news fetch error', error: e);
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchHistoricalEvents() async {
    try {
      final response = await _client
          .from('news')
          .select(
              '*, profiles:author_id(full_name, avatar_url, journalist_level)')
          .eq('category', 'history')
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List).map((e) => NewsArticle.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch historical events', error: e);
      return [];
    }
  }

  @override
  Future<List<NewsArticle>> fetchNews({required String category}) async {
    try {
      final response = await _client
          .from('news')
          .select(
              '*, profiles:author_id(full_name, avatar_url, journalist_level)')
          .eq('category', category)
          .eq('is_published', true)
          .order('importance', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((e) => NewsArticle.fromJson(e)).toList();
    } catch (e) {
      AppLogger.error('News fetch error', error: e);
      return [];
    }
  }
}
