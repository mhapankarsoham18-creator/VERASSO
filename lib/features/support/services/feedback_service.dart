import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [FeedbackService] instance.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

/// Service for handling user feedback and bug reports.
class FeedbackService {
  final SupabaseClient _client;

  /// Creates a [FeedbackService].
  FeedbackService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Submits user feedback to the Supabase [user_feedback] table.
  Future<void> submitFeedback({
    required FeedbackType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('user_feedback').insert({
        'user_id': userId,
        'type': type.name,
        'content': content,
        'metadata': metadata ?? {},
      });

      AppLogger.info('Feedback submitted successfully');

      // Also tag in Sentry if it's a bug
      if (type == FeedbackType.bug) {
        SentryService.addBreadcrumb(
          message: 'User reported a bug: $content',
          category: 'user_feedback',
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to submit feedback', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }
}

/// Types of feedback users can submit.
enum FeedbackType {
  /// A bug in the application.
  bug,

  /// A request for a new feature.
  feature,

  /// General feedback or comment.
  general,
}
