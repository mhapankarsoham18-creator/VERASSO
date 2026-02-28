import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Riverpod providers
/// Provider for the [FcmService] instance.
final fcmServiceProvider = Provider((ref) {
  return FcmService();
});

/// Provider for the [UnreadNotificationNotifier] which tracks unread count locally.
final unreadNotificationCountProvider =
    StateNotifierProvider<UnreadNotificationNotifier, int>((ref) {
  return UnreadNotificationNotifier();
});

/// Firebase Cloud Messaging (FCM) Service
/// Service for managing Firebase Cloud Messaging functionality.
class FcmService {
  final _unreadNotifications = ValueNotifier<int>(0);
  final List<NotificationModel> _notificationHistory = [];
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Clear notification history
  void clearHistory() {
    _notificationHistory.clear();
    _unreadNotifications.value = 0;
  }

  /// Delete notification by ID
  void deleteNotification(String notificationId) {
    try {
      _notificationHistory.removeWhere((n) => n.id == notificationId);
    } catch (e) {
      AppLogger.error('Delete notification error', error: e);
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    try {
      await _fcm.deleteToken();
      AppLogger.info('Notifications disabled (FCM token deleted)');
    } catch (e) {
      AppLogger.error('Disable notifications error', error: e);
    }
  }

  /// Enable notifications
  Future<bool> enableNotifications() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      final enabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      AppLogger.info('Notifications enabled: $enabled');
      return enabled;
    } catch (e) {
      AppLogger.error('Enable notifications error', error: e);
      return false;
    }
  }

  /// Get notification history
  List<NotificationModel> getNotificationHistory() {
    return List.from(_notificationHistory);
  }

  /// Get FCM token for current device
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      AppLogger.error('Get FCM token error', error: e);
      return null;
    }
  }

  /// Get unread notification count
  int getUnreadCount() => _unreadNotifications.value;

  /// Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notificationHistory.where((n) => !n.isRead).toList();
  }

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Configure foreground messaging
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp
          .listen(_handleBackgroundMessageClick);

      AppLogger.info('FCM initialized successfully');
    } catch (e) {
      AppLogger.error('FCM initialization error', error: e);
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    try {
      for (var notification in _notificationHistory) {
        notification.isRead = true;
      }
      _unreadNotifications.value = 0;
    } catch (e) {
      AppLogger.error('Mark all as read error', error: e);
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    try {
      final index =
          _notificationHistory.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notificationHistory[index].isRead = true;
        _unreadNotifications.value =
            _notificationHistory.where((n) => !n.isRead).length;
      }
    } catch (e) {
      AppLogger.error('Mark notification as read error', error: e);
    }
  }

  /// Subscribe to notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Subscribe to topic error', error: e);
    }
  }

  /// Unsubscribe from notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Unsubscribe from topic error', error: e);
    }
  }

  void _handleBackgroundMessageClick(RemoteMessage message) {
    AppLogger.info('Background message clicked: ${message.messageId}');
    // Logic to navigate can be added here or in the UI layer
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Foreground message received: ${message.messageId}');
    final notification = NotificationModel.fromRemoteMessage(message);
    _notificationHistory.add(notification);
    _unreadNotifications.value++;
  }
}

/// Model for notification data
class NotificationModel {
  /// The unique identifier.
  final String id;

  /// The type of notification.
  final NotificationType type;

  /// The title of the notification.
  final String title;

  /// The body content of the notification.
  final String body;

  /// The user ID associated with the notification.
  final String? userId;

  /// The resource ID associated with the notification.
  final String? resourceId;

  /// Additional data payload.
  final Map<String, dynamic> data;

  /// The creation timestamp.
  final DateTime createdAt;

  /// Whether the notification has been read.
  bool isRead;

  /// Creates a [NotificationModel].
  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.userId,
    this.resourceId,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  /// Creates a [NotificationModel] from a [RemoteMessage].
  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    final typeString = message.data['type'] ?? 'newMessage';
    final type = NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => NotificationType.newMessage,
    );

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      userId: message.data['userId'],
      resourceId: message.data['resourceId'],
      data: message.data,
      createdAt: DateTime.now(),
      isRead: false,
    );
  }
}

/// Notification types that the app supports
enum NotificationType {
  /// A new message notification.
  newMessage,

  /// A new post notification.
  newPost,

  /// A comment notification.
  comment,

  /// A new follower notification.
  follower,

  /// A 2FA challenge notification.
  twoFactorChallenge,

  /// A device login notification.
  deviceLogin,

  /// A mention in a post notification.
  mentionPost,

  /// A like on a post notification.
  likePost,

  /// A reply to a comment notification.
  replyToComment,

  /// A job-related notification.
  job,
}

/// Notifier for unread notification count
class UnreadNotificationNotifier extends StateNotifier<int> {
  /// Creates an [UnreadNotificationNotifier].
  UnreadNotificationNotifier() : super(0);

  /// Decrements the unread count.
  void decrement() => state = (state - 1).clamp(0, double.maxFinite.toInt());

  /// Increments the unread count.
  void increment() => state++;

  /// Marks all notifications as read (resets count to 0).
  void markAllRead() => state = 0;

  /// Sets the unread count to a specific value.
  void setCount(int count) => state = count;
}
