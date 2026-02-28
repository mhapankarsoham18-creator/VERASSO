import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../monitoring/sentry_service.dart';

/// Service responsible for logging security-sensitive events to a permanent audit trail.
///
/// It persists logs to a remote database (Supabase) and also logs critical
/// events as breadcrumbs to Sentry for real-time monitoring and alerting.
class AuditLogService {
  final SupabaseClient _client;

  /// Creates an [AuditLogService]. If [client] is null, it uses the global [SupabaseService] client.
  AuditLogService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Logs a security event to the audit trail and Sentry.
  ///
  /// This method records the event in the `security_audit_logs` table in Supabase
  /// and also sends a breadcrumb to Sentry for real-time monitoring.
  ///
  /// - [type]: The type of the event (e.g., 'authentication', 'authorization', 'data_access').
  /// - [action]: The specific action performed (e.g., 'login_success', 'login_failure', 'data_read').
  /// - [severity]: The severity level of the event (e.g., 'critical', 'high', 'medium', 'low').
  /// - [metadata]: Optional additional data related to the event.
  Future<void> logEvent({
    required String type,
    required String action,
    required String severity,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _client.auth.currentUser;

      await _client.from('security_audit_logs').insert({
        'user_id': user?.id,
        'event_type': type,
        'action': action,
        'severity': severity,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });

      // Also add a breadcrumb to Sentry for immediate context
      SentryService.addBreadcrumb(
        message: 'Audit Log: $action',
        category: 'security',
        level: _getSentryLevel(severity),
        data: metadata,
      );
    } catch (e) {
      // Fail silent but log to Sentry
      SentryService.captureException(e,
          hint: 'Failed to log audit event: $action');
    }
  }

  SentryLevel _getSentryLevel(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return SentryLevel.error;
      case 'medium':
        return SentryLevel.warning;
      case 'low':
      default:
        return SentryLevel.info;
    }
  }
}
