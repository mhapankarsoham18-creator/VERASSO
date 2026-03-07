import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/search_service.dart';
import '../models/search_results.dart';

/// Provider for the [SearchController] which manages search state.
final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<SearchResults>>((ref) {
  return SearchController(ref.watch(searchServiceProvider));
});

/// Controller that manages search state and execution.
class SearchController extends StateNotifier<AsyncValue<SearchResults>> {
  final SearchService _searchService;

  /// Creates a [SearchController] and initializes with empty data.
  SearchController(this._searchService)
      : super(AsyncData(SearchResults(users: [], posts: [], groups: [])));

  /// Clears the current search state.
  void clear() {
    state = AsyncData(SearchResults(users: [], posts: [], groups: []));
  }

  /// Executes a global search across all categories (users, posts, groups).
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = AsyncData(SearchResults(users: [], posts: [], groups: []));
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _searchService.searchAll(query));
  }

  /// Executes a search specifically for groups.
  Future<void> searchGroups(String query) async {
    if (query.trim().isEmpty) {
      state = AsyncData(SearchResults(users: [], posts: [], groups: []));
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final groups = await _searchService.searchGroups(query);
      return SearchResults(users: [], posts: [], groups: groups);
    });
  }

  /// Executes a search specifically for posts.
  Future<void> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      state = AsyncData(SearchResults(users: [], posts: [], groups: []));
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final posts = await _searchService.searchPosts(query);
      return SearchResults(users: [], posts: posts, groups: []);
    });
  }

  /// Executes a search specifically for users.
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = AsyncData(SearchResults(users: [], posts: [], groups: []));
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final users = await _searchService.searchUsers(query);
      return SearchResults(users: users, posts: [], groups: []);
    });
  }
}
