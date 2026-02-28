import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Future provider for the current user's [NotificationPreferences].
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final service = ref.read(notificationPreferencesServiceProvider);
  return service.getPreferences();
});

/// Riverpod providers
/// Provider for the [NotificationPreferencesService] instance.
final notificationPreferencesServiceProvider = Provider((ref) {
  return NotificationPreferencesService();
});

/// Provider for the [NotificationPreferencesNotifier] which manages preference state.
/// Provider for the [NotificationPreferencesNotifier] which manages preference state.
final notificationPreferencesStateProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(
    ref.read(notificationPreferencesServiceProvider),
  ),
);

/// Notification preferences model
class NotificationPreferences {
  /// Whether to receive notifications for new messages.
  bool newMessage;

  /// Whether to receive notifications for new posts.
  bool newPost;

  /// Whether to receive notifications for comments.
  bool comment;

  /// Whether to receive notifications for new followers.
  bool follower;

  /// Whether to receive notifications for 2FA challenges.
  bool twoFactorChallenge;

  /// Whether to receive notifications for device logins.
  bool deviceLogin;

  /// Whether to receive notifications for post mentions.
  bool mentionPost;

  /// Whether to receive notifications for post likes.
  bool likePost;

  /// Whether to receive notifications for comment replies.
  bool replyToComment;

  /// Whether to enable notification sounds.
  bool enableSound;

  /// Whether to enable vibration for notifications.
  bool enableVibration;

  /// Whether to enable the app icon badge.
  bool enableBadge;

  /// The start time for quiet hours, during which notifications are suppressed.
  TimeOfDay? quietHoursStart;

  /// The end time for quiet hours.
  TimeOfDay? quietHoursEnd;

  /// Whether quiet hours are currently enabled.
  bool enableQuietHours;

  /// Creates a [NotificationPreferences] instance with specified or default values.
  NotificationPreferences({
    this.newMessage = true,
    this.newPost = true,
    this.comment = true,
    this.follower = true,
    this.twoFactorChallenge = true,
    this.deviceLogin = true,
    this.mentionPost = true,
    this.likePost = true,
    this.replyToComment = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableBadge = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.enableQuietHours = false,
  });

  /// Create from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      newMessage: json['new_message'] ?? true,
      newPost: json['new_post'] ?? true,
      comment: json['comment'] ?? true,
      follower: json['follower'] ?? true,
      twoFactorChallenge: json['two_factor_challenge'] ?? true,
      deviceLogin: json['device_login'] ?? true,
      mentionPost: json['mention_post'] ?? true,
      likePost: json['like_post'] ?? true,
      replyToComment: json['reply_to_comment'] ?? true,
      enableSound: json['enable_sound'] ?? true,
      enableVibration: json['enable_vibration'] ?? true,
      enableBadge: json['enable_badge'] ?? true,
      quietHoursStart: json['quiet_hours_start'] != null
          ? _parseTimeOfDay(json['quiet_hours_start'])
          : null,
      quietHoursEnd: json['quiet_hours_end'] != null
          ? _parseTimeOfDay(json['quiet_hours_end'])
          : null,
      enableQuietHours: json['enable_quiet_hours'] ?? false,
    );
  }

  /// Check if in quiet hours
  bool isInQuietHours() {
    if (!enableQuietHours || quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final startMinutes = quietHoursStart!.hour * 60 + quietHoursStart!.minute;
    final endMinutes = quietHoursEnd!.hour * 60 + quietHoursEnd!.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Quiet hours span midnight
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Check if notification type is enabled
  bool isNotificationTypeEnabled(String notificationType) {
    switch (notificationType) {
      case 'newMessage':
        return newMessage;
      case 'newPost':
        return newPost;
      case 'comment':
        return comment;
      case 'follower':
        return follower;
      case 'twoFactorChallenge':
        return twoFactorChallenge;
      case 'deviceLogin':
        return deviceLogin;
      case 'mentionPost':
        return mentionPost;
      case 'likePost':
        return likePost;
      case 'replyToComment':
        return replyToComment;
      case 'job':
        return true; // Default to true for now
      default:
        return true;
    }
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'new_message': newMessage,
      'new_post': newPost,
      'comment': comment,
      'follower': follower,
      'two_factor_challenge': twoFactorChallenge,
      'device_login': deviceLogin,
      'mention_post': mentionPost,
      'like_post': likePost,
      'reply_to_comment': replyToComment,
      'enable_sound': enableSound,
      'enable_vibration': enableVibration,
      'enable_badge': enableBadge,
      'quiet_hours_start': quietHoursStart?.toString(),
      'quiet_hours_end': quietHoursEnd?.toString(),
      'enable_quiet_hours': enableQuietHours,
    };
  }

  /// Parse TimeOfDay from string
  static TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null) return null;
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      AppLogger.warning('Parse time of day error', error: e);
      return null;
    }
  }
}

/// Notifier for notification preferences
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  final NotificationPreferencesService _service;

  /// Creates a [NotificationPreferencesNotifier].
  NotificationPreferencesNotifier(this._service)
      : super(NotificationPreferences());

  /// Load preferences from database
  Future<void> loadPreferences() async {
    try {
      final prefs = await _service.getPreferences();
      state = prefs;
    } catch (e) {
      AppLogger.warning('Load preferences error', error: e);
    }
  }

  /// Set quiet hours
  Future<void> setQuietHours(
    TimeOfDay start,
    TimeOfDay end,
    bool enabled,
  ) async {
    try {
      await _service.setQuietHours(start, end, enabled);
      await loadPreferences();
    } catch (e) {
      AppLogger.error('Set quiet hours error', error: e);
      rethrow;
    }
  }

  /// Toggle notification type
  Future<void> toggleNotificationType(
    String notificationType,
    bool enabled,
  ) async {
    try {
      await _service.toggleNotificationType(notificationType, enabled);
      await loadPreferences();
    } catch (e) {
      AppLogger.error('Toggle notification type error', error: e);
      rethrow;
    }
  }

  /// Update preferences
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    try {
      await _service.updatePreferences(prefs);
      state = prefs;
    } catch (e) {
      AppLogger.error('Update preferences error', error: e);
      rethrow;
    }
  }
}

/// Notification Preferences Service
/// Service for managing user notification preferences via Supabase.
class NotificationPreferencesService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user's notification preferences.
  Future<NotificationPreferences> getPreferences() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      AppLogger.warning('Get preferences error', error: e);
      // Return default preferences if not found
      return NotificationPreferences();
    }
  }

  /// Resets preferences to their default values.
  Future<void> resetToDefaults() async {
    try {
      await updatePreferences(NotificationPreferences());
    } catch (e) {
      AppLogger.error('Reset to defaults error', error: e);
      throw Exception('Failed to reset preferences: $e');
    }
  }

  /// Sets the quiet hours schedule.
  ///
  /// [start] is the start time.
  /// [end] is the end time.
  /// [enabled] enables or disables quiet hours.
  Future<void> setQuietHours(
    TimeOfDay start,
    TimeOfDay end,
    bool enabled,
  ) async {
    try {
      final prefs = await getPreferences();
      prefs.quietHoursStart = start;
      prefs.quietHoursEnd = end;
      prefs.enableQuietHours = enabled;

      await updatePreferences(prefs);
    } catch (e) {
      AppLogger.error('Set quiet hours error', error: e);
      throw Exception('Failed to set quiet hours: $e');
    }
  }

  /// Toggles the notification badge on the app icon.
  Future<void> toggleBadge(bool enabled) async {
    try {
      final prefs = await getPreferences();
      prefs.enableBadge = enabled;
      await updatePreferences(prefs);
    } catch (e) {
      AppLogger.error('Toggle badge error', error: e);
      throw Exception('Failed to toggle badge: $e');
    }
  }

  /// Toggles a specific type of notification.
  Future<void> toggleNotificationType(
    String notificationType,
    bool enabled,
  ) async {
    try {
      final prefs = await getPreferences();

      switch (notificationType) {
        case 'newMessage':
          prefs.newMessage = enabled;
          break;
        case 'newPost':
          prefs.newPost = enabled;
          break;
        case 'comment':
          prefs.comment = enabled;
          break;
        case 'follower':
          prefs.follower = enabled;
          break;
        case 'twoFactorChallenge':
          prefs.twoFactorChallenge = enabled;
          break;
        case 'deviceLogin':
          prefs.deviceLogin = enabled;
          break;
        case 'mentionPost':
          prefs.mentionPost = enabled;
          break;
        case 'likePost':
          prefs.likePost = enabled;
          break;
        case 'replyToComment':
          prefs.replyToComment = enabled;
          break;
      }

      await updatePreferences(prefs);
    } catch (e) {
      AppLogger.error('Toggle notification type error', error: e);
      throw Exception('Failed to toggle notification type: $e');
    }
  }

  /// Toggles notification sounds.
  Future<void> toggleSound(bool enabled) async {
    try {
      final prefs = await getPreferences();
      prefs.enableSound = enabled;
      await updatePreferences(prefs);
    } catch (e) {
      AppLogger.error('Toggle sound error', error: e);
      throw Exception('Failed to toggle sound: $e');
    }
  }

  /// Toggles notification vibration.
  Future<void> toggleVibration(bool enabled) async {
    try {
      final prefs = await getPreferences();
      prefs.enableVibration = enabled;
      await updatePreferences(prefs);
    } catch (e) {
      AppLogger.error('Toggle vibration error', error: e);
      throw Exception('Failed to toggle vibration: $e');
    }
  }

  /// Updates the notification preferences in the database.
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client.from('notification_preferences').upsert({
        'user_id': userId,
        ...preferences.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      AppLogger.info('Preferences updated successfully');
    } catch (e) {
      AppLogger.error('Update preferences error', error: e);
      throw Exception('Failed to update preferences: $e');
    }
  }
}
