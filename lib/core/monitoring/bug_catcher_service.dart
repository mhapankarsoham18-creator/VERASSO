import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Provider for the [BugCatcherService] instance.
final bugCatcherServiceProvider = Provider((ref) => BugCatcherService());

/// Service for reporting bugs and rewarding users with XP and badges.
class BugCatcherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calculates badge level based on unique bugs caught
  String getBadgeLevel(int uniqueBugsCount) {
    if (uniqueBugsCount >= 50) return 'Platinum';
    if (uniqueBugsCount >= 20) return 'Gold';
    if (uniqueBugsCount >= 5) return 'Silver';
    if (uniqueBugsCount >= 1) return 'Bronze';
    return 'None';
  }

  /// Submits a bug report with uniqueness check
  /// Only the first 5 unique reports for a bug receive full XP/Badges
  Future<Map<String, dynamic>> submitReport({
    required String title,
    required String description,
    required String category,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create a hash to identify unique bugs
      final bugHash =
          '${category.toLowerCase()}_${title.toLowerCase().replaceAll(' ', '_')}';

      // Submit the report via secure RPC
      final result = await _supabase.rpc('submit_bug_report', params: {
        'p_title': title,
        'p_description': description,
        'p_category': category,
        'p_bug_hash': bugHash,
        'p_metadata': metadata,
      });

      if (result['success'] == true) {
        final int xpAwarded = result['xp_awarded'] ?? 0;

        return {
          'success': true,
          'status': xpAwarded > 0 ? 'valid' : 'saturated',
          'message': xpAwarded > 0
              ? 'Bug reported successfully! $xpAwarded XP awarded.'
              : 'This bug has already reached its reward limit. Report accepted.',
          'xp_awarded': xpAwarded,
          'report_id': result['report_id'],
        };
      }

      throw Exception('Server failed to process report');
    } catch (e) {
      SentryService.captureException(e, stackTrace: StackTrace.current);
      return {'success': false, 'error': e.toString()};
    }
  }
}
