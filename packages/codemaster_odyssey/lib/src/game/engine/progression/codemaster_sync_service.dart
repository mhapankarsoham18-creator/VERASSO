import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'player_state.dart';

/// Provider for the [CodemasterSyncService].
final codemasterSyncServiceProvider = Provider<CodemasterSyncService>((ref) {
  return CodemasterSyncService();
});

/// Handles synchronizing the Codemaster Odyssey [PlayerState] with the Supabase backend.
class CodemasterSyncService {
  /// Attempts to fetch the remote state from Supabase.
  Future<Map<String, dynamic>?> fetchRemoteState() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return null;

    try {
      final response = await client
          .from('codemaster_saves')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e, stack) {
      debugPrint('Failed to fetch Codemaster remote state: $e\n$stack');
      return null;
    }
  }

  /// Syncs the current [state] to the `codemaster_saves` table in Supabase.
  Future<void> syncState(PlayerState state) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      debugPrint('Cannot sync player state: No user logged in.');
      return;
    }

    try {
      await client.from('codemaster_saves').upsert({
        'user_id': user.id,
        'fragments': state.fragments,
        'level': state.level,
        'health': state.health,
        'maxHealth': state.maxHealth,
        'currentRegion': state.currentRegion,
        'arcIndex': state.unlockedArcs.length - 1,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Successfully synced Codemaster state to backend.');
    } catch (e, stack) {
      debugPrint('Failed to sync Codemaster state: $e\n$stack');
    }
  }
}
