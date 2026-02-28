import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stargazing_model.dart';

/// Provider for the [AstronomyRepository].
final astronomyRepositoryProvider = Provider<AstronomyRepository>((ref) {
  return AstronomyRepository(Supabase.instance.client);
});

/// Repository for managing astronomy-related data, such as stargazing logs.
class AstronomyRepository {
  final SupabaseClient _client;

  /// Creates an [AstronomyRepository] instance.
  AstronomyRepository(this._client);

  /// Creates a new stargazing log entry.
  Future<void> createLog({
    required String userId,
    required String celestialObject,
    required String equipmentType,
    String? locationName,
    required int skyRating,
    String? notes,
    String? mediaUrl,
  }) async {
    await _client.from('stargazing_logs').insert({
      'user_id': userId,
      'celestial_object': celestialObject,
      'equipment_type': equipmentType,
      'location_name': locationName,
      'sky_rating': skyRating,
      'notes': notes,
      'media_url': mediaUrl,
    });
  }

  /// Retrieves all community stargazing logs.
  Future<List<StargazingLog>> getCommunityLogs() async {
    final response = await _client
        .from('stargazing_logs')
        .select('*, profiles:user_id(full_name, avatar_url)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StargazingLog.fromJson(json))
        .toList();
  }

  /// Retrieves stargazing logs for a specific user.
  Future<List<StargazingLog>> getUserLogs(String userId) async {
    final response = await _client
        .from('stargazing_logs')
        .select('*, profiles:user_id(full_name, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StargazingLog.fromJson(json))
        .toList();
  }
}
