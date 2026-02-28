import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../../core/services/supabase_service.dart';
import 'community_model.dart';

/// Provider for the [CommunityRepository].
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

/// Repository for managing learning communities and subject-based groups.
class CommunityRepository {
  final SupabaseClient _client;

  /// Creates a [CommunityRepository] that uses the provided Supabase [client] or
  /// falls back to the global [SupabaseService.client].
  CommunityRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Returns a list of communities recommended for the user.
  Future<List<Community>> getRecommendedCommunities() async {
    try {
      final response = await _client
          .from('communities')
          .select()
          .limit(10)
          .order('member_count', ascending: false);

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get recommended communities', error: e);
      return [];
    }
  }

  /// Joins a specific community for the given [userId].
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      await _client.rpc('join_community', params: {
        'p_community_id': communityId,
        'p_user_id': userId,
      });
    } catch (e) {
      AppLogger.error('Failed to join community', error: e);
      rethrow;
    }
  }

  /// Searches for communities matching the [query] in name, description, or subject.
  Future<List<Community>> searchCommunities(String query) async {
    try {
      final response = await _client
          .from('communities')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%,subject.ilike.%$query%')
          .order('member_count', ascending: false);

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to search communities', error: e);
      return [];
    }
  }
}
