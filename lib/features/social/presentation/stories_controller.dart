import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/story_model.dart';
import '../data/story_repository.dart';

/// Provider for the list of active stories.
final storiesProvider =
    StateNotifierProvider<StoriesNotifier, AsyncValue<List<Story>>>((ref) {
  return StoriesNotifier(ref.watch(storyRepositoryProvider));
});

/// Provider for the [StoryRepository].
final storyRepositoryProvider = Provider((ref) => StoryRepository());

/// State notifier for managing active stories.
class StoriesNotifier extends StateNotifier<AsyncValue<List<Story>>> {
  final StoryRepository _repository;

  /// Creates a [StoriesNotifier] instance.
  StoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStories();
  }

  /// Loads active stories from the repository.
  Future<void> loadStories() async {
    state = const AsyncValue.loading();
    try {
      final stories = await _repository.getActiveStories();
      state = AsyncValue.data(stories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
