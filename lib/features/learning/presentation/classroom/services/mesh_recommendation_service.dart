import 'package:flutter_riverpod/legacy.dart';

/// No-op provider for Mesh Recommendation Service.
final meshRecommendationServiceProvider = StateNotifierProvider<MeshRecommendationService, List<String>>((ref) {
  return MeshRecommendationService();
});

/// No-op implementation of Mesh Recommendation Service.
class MeshRecommendationService extends StateNotifier<List<String>> {
  MeshRecommendationService() : super([]);
  List<String> getRecommendations(String subject) => [];
}
