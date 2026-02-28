import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Represents a single unit of record in the audit trail.
class AuditLogEntry {
  /// Unique identifier for the audit log entry.
  final String id;

  /// The ID of the user who performed the action.
  final String userId;

  /// The type or category of the audit event.
  final String eventType;

  /// A descriptive message for the event.
  final String description;

  /// Optional metadata associated with the event.
  final Map<String, dynamic> metadata;

  /// The timestamp when the entry was created.
  final DateTime createdAt;

  /// Creates an [AuditLogEntry].
  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.description,
    required this.metadata,
    required this.createdAt,
  });

  /// Creates an [AuditLogEntry] from a JSON map.
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      userId: json['user_id'],
      eventType: json['event_type'],
      description: json['description'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Service for managing and retrieving application audit logs from Supabase.
class AuditLogService {
  final _supabase = Supabase.instance.client;

  /// Retrieves all audit logs for the currently authenticated user.
  Future<List<AuditLogEntry>> getLogs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('audit_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AuditLogEntry.fromJson(json))
          .toList();
    } catch (e) {
      // If table doesn't exist, return empty for demo/MVP
      return [];
    }
  }

  /// Logs a new audit event for the current user.
  Future<void> logEvent({
    required String eventType,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('audit_logs').insert({
        'user_id': userId,
        'event_type': eventType,
        'description': description,
        'metadata': metadata,
      });
    } catch (e) {
      SentryService.captureException(e, hint: 'Audit logging failed');
    }
  }
}
