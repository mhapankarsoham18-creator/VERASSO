import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all badges awarded to a user
  Future<List<Map<String, dynamic>>> fetchUserBadges(String userId) async {
    return await _supabase
       .from('user_badges')
       .select('*')
       .eq('user_id', userId)
       .order('awarded_at', ascending: false);
  }

  /// Manually award a badge to a user (usually this should be done via Edge Functions for security).
  /// For now, provided as a utility if Admin logic runs it.
  Future<void> awardBadge(String userId, String badgeName) async {
    // Requires adequate RLS bypassing or permissions if users can't award them freely
    await _supabase.from('user_badges').insert({
      'user_id': userId,
      'badge_name': badgeName,
    });
  }

  /// Compute user trust score metrics
  Future<int> computeTrustScore(String userId) async {
     // A simple initial heuristic:
     // - Badge counts (+10 each)
     // - Feed posts likes (+1 each)
     
     int score = 0;
     
     try {
       final badges = await fetchUserBadges(userId);
       score += (badges.length * 10);
       
       // Calculate total likes on posts authored by this user
       final posts = await _supabase
         .from('posts')
         .select('likes')
         .eq('author_id', userId);
         
       for (var post in posts) {
          score += ((post['likes'] ?? 0) as int);
       }
       
       return score;
     } catch (e) {
       return 0; // default zero
     }
  }
}
