import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/services/stories_service.dart';

/// Provider for [StoriesService]
final storiesServiceProvider = Provider<StoriesService>((ref) {
  return StoriesService();
});
