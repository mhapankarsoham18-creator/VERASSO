import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../gamification/services/gamification_event_bus.dart';
import 'talent_model.dart';

/// Provides access to the [TalentRepository] via Riverpod.
final talentRepositoryProvider = Provider<TalentRepository>((ref) {
  final eventBus = ref.watch(gamificationEventBusProvider);
  return TalentRepository(eventBus: eventBus);
});

/// Repository for discovering and managing Talent posts.
///
/// This class encapsulates all Supabase access for querying and mutating the
/// `talents` table as well as updating age verification status on profiles.
class TalentRepository {
  final SupabaseClient _client;
  final GamificationEventBus? _eventBus;

  /// Creates a [TalentRepository] that uses the provided Supabase [client] or
  /// falls back to the global [SupabaseService.client].
  TalentRepository({
    SupabaseClient? client,
    GamificationEventBus? eventBus,
  })  : _client = client ?? SupabaseService.client,
        _eventBus = eventBus;

  /// Creates a new [talent] record in the `talents` table.
  ///
  /// [talent] is the [TalentPost] object to creation.
  Future<void> createTalent(TalentPost talent) async {
    await _client.from('talents').insert(talent.toJson());

    // Hook to track talent listed
    _eventBus?.track(GamificationAction.talentListed, talent.userId);
  }

  /// Returns the list of public [TalentPost]s ordered by featured status and
  /// recency, with pagination support.
  Future<List<TalentPost>> getTalents({int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('talents')
          .select('*, profiles(full_name, avatar_url, is_mentor)')
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TalentPost.fromJson(json))
          .toList();
    } catch (e) {
      // If user is not age-verified, RLS will block this and throw an error
      // We handle it in the UI/Controller
      rethrow;
    }
  }

  /// Updates age verification status for a profile with the given [userId].
  ///
  /// The optional [docUrl] can be used to persist a verification document
  /// reference alongside the boolean [isVerified] flag.
  Future<void> updateVerificationStatus(
      String userId, String? docUrl, bool isVerified) async {
    await _client.from('profiles').update({
      'is_age_verified': isVerified,
      'verification_url': docUrl,
    }).eq('id', userId);
  }
}
