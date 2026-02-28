import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'mentor_model.dart';
import 'talent_model.dart';

/// Provider for the [MentorRepository] instance.
final mentorRepositoryProvider = Provider<MentorRepository>((ref) {
  return MentorRepository();
});

/// Repository for managing mentor profiles and packages.
class MentorRepository {
  final SupabaseClient _client;

  /// Creates a [MentorRepository].
  MentorRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  // --- Mentor Onboarding & Verification ---

  /// Fetches talent packages offered by a specific mentor.
  Future<List<TalentPost>> getMentorPackages(String mentorUserId) async {
    final response = await _client
        .from('talents')
        .select('*, profiles(full_name, avatar_url, is_mentor)')
        .eq('user_id', mentorUserId)
        .eq('is_mentor_package', true);

    return (response as List).map((json) => TalentPost.fromJson(json)).toList();
  }

  /// Fetches the current user's mentor profile.
  Future<MentorProfile?> getMyMentorProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('mentor_profiles')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return MentorProfile.fromJson(response);
  }

  // --- Directory ---

  /// Fetches a list of verified mentors.
  Future<List<MentorProfile>> getVerifiedMentors() async {
    final response = await _client
        .from('mentor_profiles')
        .select('*, profiles(full_name, avatar_url, is_mentor)')
        .eq('verification_status', 'verified');

    return (response as List)
        .map((json) => MentorProfile.fromJson(json))
        .toList();
  }

  // --- Mentor Actions ---

  /// Registers a user as a mentor.
  Future<void> registerAsMentor(MentorProfile profile) async {
    await _client.from('mentor_profiles').upsert(profile.toJson());

    // Update profile is_mentor flag
    await _client
        .from('profiles')
        .update({'is_mentor': true}).eq('id', profile.userId);
  }
}
