import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'talent_profile_model.dart';

/// Provider for the [TalentProfileRepository] instance.
final talentProfileRepositoryProvider =
    Provider<TalentProfileRepository>((ref) => TalentProfileRepository());

/// Repository for managing detailed talent profiles.
class TalentProfileRepository {
  final SupabaseClient _client;

  /// Creates a [TalentProfileRepository].
  TalentProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Fetches a talent profile by user ID.
  Future<TalentProfile?> getTalentProfile(String userId) async {
    final response = await _client
        .from('talent_profiles')
        .select('*, profiles(username, full_name, avatar_url)')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TalentProfile.fromJson(response);
  }

  /// Fetches a list of verified mentors (exposed via talent profiles).
  Future<List<TalentProfile>> getVerifiedMentors() async {
    final response = await _client
        .from('talent_profiles')
        .select('*, profiles(username, full_name, avatar_url)')
        .limit(50);

    return (response as List).map((e) => TalentProfile.fromJson(e)).toList();
  }

  /// Searches for mentors whose name, headline, or skills match the [query].
  Future<List<TalentProfile>> searchMentors(String query) async {
    try {
      final response = await _client
          .from('talent_profiles')
          .select('*, profiles(username, full_name, avatar_url)')
          .or('full_name.ilike.%$query%,headline.ilike.%$query%,skills.cs.{$query}')
          .limit(20);

      return (response as List).map((e) => TalentProfile.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Creates or updates a talent profile.
  Future<void> upsertTalentProfile(TalentProfile profile) async {
    await _client.from('talent_profiles').upsert(profile.toJson());
  }
}
