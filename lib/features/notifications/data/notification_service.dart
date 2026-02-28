import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../../core/services/supabase_service.dart';
import '../models/notification_model.dart';

// Provider
/// Provider for the [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Stream Provider for real-time updates
/// Stream provider for the real-time unread notification count.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCountStream();
});

// Background handler must be top-level
/// Top-level background message handler for FCM.
///
/// This must be a top-level function or static method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you needed to spawn an isolate or initialize Supabase here, you could.
  // For now, just log it.
  AppLogger.info("Handling a background message: ${message.messageId}");
}

/// Service for managing notifications via Supabase and FCM.
class NotificationService {
  final SupabaseClient _client;
  final FirebaseMessaging _fcm;

  /// Creates a [NotificationService] instance.
  /// Optionally accepts [FirebaseMessaging] for testing.
  NotificationService({SupabaseClient? client, FirebaseMessaging? fcm})
      : _client = client ?? SupabaseService.client,
        _fcm = fcm ?? FirebaseMessaging.instance;

  // Create notification (Usually called by backend triggers, but we do it client-side for MVP hooks)
  /// Creates a notification in the database.
  ///
  /// [targetUserId] is the ID of the user receiving the notification.
  /// [type] is the [NotificationType].
  /// [title] is the notification title.
  /// [body] is the notification body content.
  /// [data] is optional metadata.
  Future<void> createNotification({
    required String targetUserId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': targetUserId,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      AppLogger.info('Error creating notification: $e');
    }
  }

  // Helper method if we just want a future
  /// Fetches a list of notifications for the current user.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } catch (e) {
      AppLogger.info('Error fetching notifications: $e');
      return [];
    }
  }

  // Stream of notifications
  /// Returns a stream of notifications for the current user, ordered by creation time.
  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  /// Returns a stream of the count of unread notifications for the current user.
  Stream<int> getUnreadCountStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          return data.where((json) => json['read_at'] == null).length;
        });
  }

  /// Initialize FCM and register handlers
  Future<void> initializeFCM() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.info('User granted provisional permission');
      } else {
        AppLogger.info('User declined or has not accepted permission');
        return;
      }

      // 2. Get Token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToProfile(token);
      }

      // 3. Listen for Token Refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToProfile(newToken);
      });

      // 4. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info(
            'Foreground Notification: ${message.notification?.title}');

        // In a production app, you might use flutter_local_notifications here
        // to show a heads-up display if the user is in a different section.
      });

      // 5. Handle notification clicks (Persistence/Navigation context)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('Notification clicked: ${message.notification?.title}');
        // Navigation logic would go here
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('Launched from notification: ${initialMessage.data}');
      }

      // 6. Periodic token refresh (Heartbeat) - check every time service starts
      _refreshFCMToken();
    } catch (e) {
      AppLogger.info('Error initializing FCM: $e');
    }
  }

  // Mark all as read
  /// Marks all notifications as read for the current user.
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .filter('read_at', 'is', null);
  }

  // Mark single as read
  /// Marks a single notification as read.
  ///
  /// [notificationId] is the ID of the notification to mark as read.
  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update(
        {'read_at': DateTime.now().toIso8601String()}).eq('id', notificationId);
  }

  // Send job notification (migrated from NotificationsRepository)
  /// Sends a job-related notification.
  ///
  /// [userId] is the target user ID.
  /// [title] is the notification title.
  /// [message] is the notification message.
  /// [jobId] is the related job ID.
  Future<void> sendJobNotification({
    required String userId,
    required String title,
    required String message,
    required String jobId,
  }) async {
    await createNotification(
      targetUserId: userId,
      type: NotificationType
          .system, // Using system as fallback, or add 'job' to enum
      title: title,
      body: message,
      data: {'jobId': jobId, 'subType': 'job'},
    );
  }

  Future<void> _refreshFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToProfile(token);
      }
    } catch (e) {
      AppLogger.error('Failed to refresh FCM token', error: e);
    }
  }

  Future<void> _saveTokenToProfile(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      AppLogger.info('FCM Token saved to profile');
    } catch (e) {
      AppLogger.error('Error saving FCM token', error: e);
    }
  }
}
