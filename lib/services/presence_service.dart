// Phase 2: Collaborative Features - Real-time Presence & Notifications
// Enables multi-user awareness and instant edit notifications

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Represents an active user in the system with their presence metadata.
class ActiveUser {
  /// The unique identifier for the user.
  final String userId;

  /// The user's current cursor position in a document.
  final int cursorPosition;

  /// Whether the user is currently editing a document.
  final bool isEditing;

  /// The timestamp of the user's last edit.
  final DateTime lastEdit;

  /// Creates a new [ActiveUser] instance.
  ActiveUser({
    required this.userId,
    required this.cursorPosition,
    required this.isEditing,
    required this.lastEdit,
  });

  /// Creates an [ActiveUser] from a JSON map.
  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['user_id'] as String,
      cursorPosition: json['cursor_position'] as int? ?? 0,
      isEditing: json['is_editing'] as bool? ?? false,
      lastEdit: DateTime.parse(
          json['last_edit'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Multi-user Notification Service - Real-time edit alerts
class CollaborativeNotificationService {
  /// The Supabase client used for communication.
  final SupabaseClient _supabase;

  /// The unique identifier for the document being collaborated on.
  final String documentId;

  late RealtimeChannel _channel;
  final _editNotificationController =
      StreamController<EditNotification>.broadcast();

  /// Creates a [CollaborativeNotificationService] instance.
  CollaborativeNotificationService({
    required this.documentId,
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  /// Gets the stream of edit notifications.
  Stream<EditNotification> get editNotifications =>
      _editNotificationController.stream;

  /// Broadcast an edit to other users
  Future<void> broadcastEdit({
    required String userId,
    required int offset,
    required String deletedText,
    required String insertedText,
    required int timestamp,
  }) async {
    try {
      await _supabase.from('document_edits').insert({
        'document_id': documentId,
        'user_id': userId,
        'offset': offset,
        'deleted_text': deletedText,
        'inserted_text': insertedText,
        'timestamp': timestamp,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.error('Error broadcasting edit', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Start listening for edit notifications
  Future<void> startListening() async {
    _channel = _supabase.channel('edits:$documentId');

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'document_edits',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'document_id',
        value: documentId,
      ),
      callback: (payload) {
        final edit = EditNotification.fromJson(
          payload.newRecord,
        );
        _editNotificationController.sink.add(edit);
      },
    );

    _channel.subscribe();
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _supabase.removeChannel(_channel);
    await _editNotificationController.close();
  }
}

/// Represents a notification about a document edit.
class EditNotification {
  /// The ID of the document being edited.
  final String documentId;

  /// The ID of the user who made the edit.
  final String userId;

  /// The character offset where the edit occurred.
  final int offset;

  /// The text that was deleted during the edit.
  final String deletedText;

  /// The text that was inserted during the edit.
  final String insertedText;

  /// The timestamp of the edit.
  final int timestamp;

  /// Creates a new [EditNotification] instance.
  EditNotification({
    required this.documentId,
    required this.userId,
    required this.offset,
    required this.deletedText,
    required this.insertedText,
    required this.timestamp,
  });

  /// Creates an [EditNotification] from a JSON map.
  factory EditNotification.fromJson(Map<String, dynamic> json) {
    return EditNotification(
      documentId: json['document_id'] as String,
      userId: json['user_id'] as String,
      offset: json['offset'] as int,
      deletedText: json['deleted_text'] as String? ?? '',
      insertedText: json['inserted_text'] as String? ?? '',
      timestamp: json['timestamp'] as int,
    );
  }
}

/// Data Models for Collaborative Features

/// Represents an event where users join or leave a document session.
class PresenceEvent {
  /// The type of presence event ('join' or 'leave').
  final String type; // 'join' or 'leave'

  /// The list of users involved in the event.
  final List<ActiveUser> users;

  /// The timestamp of the event.
  final DateTime timestamp;

  /// Creates a new [PresenceEvent] instance.
  PresenceEvent({
    required this.type,
    required this.users,
    required this.timestamp,
  });
}

/// Real-time Presence Service - Track who's currently editing
class PresenceService {
  /// The Supabase client instance.
  final SupabaseClient _supabase;

  /// The unique identifier for the current user.
  final String userId;

  /// The unique identifier for the document being tracked.
  final String documentId;

  late RealtimeChannel _channel;
  final _presenceController = StreamController<PresenceEvent>.broadcast();
  final _activUsersController = StreamController<List<ActiveUser>>.broadcast();

  List<ActiveUser> _activeUsers = [];

  /// Creates a [PresenceService] instance for a specific user and document.
  PresenceService({
    required this.userId,
    required this.documentId,
    required SupabaseClient supabase,
  }) : _supabase = supabase {
    _initializePresence();
  }

  /// Gets the stream of active users.
  Stream<List<ActiveUser>> get activeUsersStream =>
      _activUsersController.stream;

  /// Gets the stream of presence events.
  Stream<PresenceEvent> get presenceStream => _presenceController.stream;

  /// Update editing status
  Future<void> setEditingStatus(bool isEditing) async {
    try {
      await _channel.track({
        'user_id': userId,
        'is_editing': isEditing,
        'last_edit': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.warning('Error tracking presence editing status', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Initialize presence tracking for document
  Future<void> startPresence() async {
    _channel = _supabase.channel(
      'presence:$documentId',
      opts: const RealtimeChannelConfig(
        key: 'presence',
      ),
    );

    // Subscribe to the channel - this enables presence tracking
    _channel.onPresenceSync((payload) {
      // When presence state syncs
      final presenceState = _channel.presenceState();
      _activeUsers = [];
      for (final presence in presenceState) {
        final p = (presence as dynamic).payload;
        _activeUsers.add(ActiveUser(
          userId: (p['user_id'] as String?) ?? '',
          cursorPosition: (p['cursor_position'] as int?) ?? 0,
          isEditing: (p['is_editing'] as bool?) ?? false,
          lastEdit: DateTime.parse(
              (p['last_edit'] as String?) ?? DateTime.now().toIso8601String()),
        ));
      }
      _activUsersController.sink.add(_activeUsers);
    }).onPresenceJoin((payload) {
      // When a user joins
      for (final presence in payload.newPresences) {
        final p = presence.payload;
        final joining = p['user_id'] as String? ?? '';
        _presenceController.sink.add(
          PresenceEvent(
            type: 'join',
            users: [
              ActiveUser(
                userId: joining,
                cursorPosition: (p['cursor_position'] as int?) ?? 0,
                isEditing: (p['is_editing'] as bool?) ?? false,
                lastEdit: DateTime.now(),
              )
            ],
            timestamp: DateTime.now(),
          ),
        );
      }
    }).onPresenceLeave((payload) {
      // When a user leaves
      for (final presence in payload.leftPresences) {
        final p = presence.payload;
        final leaving = p['user_id'] as String? ?? '';
        _activeUsers.removeWhere((u) => u.userId == leaving);
        _presenceController.sink.add(
          PresenceEvent(
            type: 'leave',
            users: [
              ActiveUser(
                userId: leaving,
                cursorPosition: 0,
                isEditing: false,
                lastEdit: DateTime.now(),
              )
            ],
            timestamp: DateTime.now(),
          ),
        );
      }
      _activUsersController.sink.add(_activeUsers);
    });

    _channel.subscribe();

    // Send own presence
    await _channel.track({
      'user_id': userId,
      'cursor_position': 0,
      'is_editing': false,
      'last_edit': DateTime.now().toIso8601String(),
    });
  }

  /// Stop presence tracking
  Future<void> stopPresence() async {
    await _channel.untrack();
    await _supabase.removeChannel(_channel);
    await _presenceController.close();
    await _activUsersController.close();
  }

  /// Update cursor position (for real-time cursor tracking)
  Future<void> updateCursor(int position) async {
    try {
      await _channel.track({
        'user_id': userId,
        'cursor_position': position,
        'is_editing': true,
        'last_edit': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.warning('Error tracking cursor position', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  /// Kick off async presence initialization from constructor
  void _initializePresence() {
    startPresence();
  }
}

/// Represents the current state of presence in a document.
class PresenceState {
  /// The list of active users in the document.
  final List<ActiveUser> users;

  /// Creates a new [PresenceState] instance.
  PresenceState({required this.users});

  /// Creates a [PresenceState] from a list of user presence data.
  factory PresenceState.fromJsonSync(List<dynamic> state) {
    final users = (state)
        .map((u) => ActiveUser.fromJson(u as Map<String, dynamic>))
        .toList();
    return PresenceState(users: users);
  }
}

// Supabase table for tracking real-time edits (SQL schema)
/*
CREATE TABLE IF NOT EXISTS public.document_edits (
  id BIGSERIAL PRIMARY KEY,
  document_id TEXT REFERENCES public.documents_v2(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  offset INTEGER NOT NULL,
  deleted_text TEXT,
  inserted_text TEXT,
  timestamp BIGINT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_document_edits_document ON public.document_edits(document_id);
CREATE INDEX idx_document_edits_timestamp ON public.document_edits(timestamp DESC);

ALTER TABLE public.document_edits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view edits for shared documents"
  ON public.document_edits FOR SELECT
  USING (document_id IN (
    SELECT id FROM public.documents_v2 
    WHERE user_id = auth.uid()
  ));
*/
