import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/features/notifications/services/fcm_service.dart';
import 'package:verasso/features/notifications/services/notification_preferences_service.dart';

/// Notification badge showing unread count
/// A badge widget that displays the unread notification count.
class NotificationBadge extends ConsumerWidget {
  /// Creates a [NotificationBadge].
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Notification center screen showing all notifications.
class NotificationCenterScreen extends ConsumerWidget {
  /// Creates a [NotificationCenterScreen].
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmService = ref.read(fcmServiceProvider);
    final notifications = fcmService.getNotificationHistory();
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                fcmService.markAllAsRead();
                ref
                    .read(unreadNotificationCountProvider.notifier)
                    .markAllRead();
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () {
                    fcmService.markAsRead(notification.id);
                    ref
                        .read(unreadNotificationCountProvider.notifier)
                        .decrement();
                  },
                  onDismiss: () {
                    fcmService.deleteNotification(notification.id);
                  },
                );
              },
            ),
    );
  }
}

/// Notification item widget for notification list.
class NotificationItem extends ConsumerWidget {
  /// The notification data.
  final NotificationModel notification;

  /// Callback when the item is tapped.
  final VoidCallback onTap;

  /// Callback when the item is dismissed.
  final VoidCallback? onDismiss;

  /// Creates a [NotificationItem].
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) => onDismiss?.call(),
      child: ListTile(
        leading: _buildNotificationIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  /// Build notification icon based on type
  Widget _buildNotificationIcon() {
    final (icon, color) = switch (notification.type) {
      NotificationType.newMessage => (Icons.message, Colors.blue),
      NotificationType.newPost => (Icons.post_add, Colors.green),
      NotificationType.comment => (Icons.comment, Colors.orange),
      NotificationType.follower => (Icons.person_add, Colors.purple),
      NotificationType.twoFactorChallenge => (Icons.security, Colors.red),
      NotificationType.deviceLogin => (Icons.devices, Colors.red),
      NotificationType.mentionPost => (Icons.alternate_email, Colors.blue),
      NotificationType.likePost => (Icons.favorite, Colors.red),
      NotificationType.replyToComment => (Icons.reply, Colors.orange),
      NotificationType.job => (Icons.work, Colors.blueAccent),
    };

    return Icon(icon, color: color);
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

/// Notification preferences UI
/// Screen for managing user notification settings and preferences.
class NotificationSettingsScreen extends ConsumerWidget {
  /// Creates a [NotificationSettingsScreen].
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final preferencesNotifier =
        ref.read(notificationPreferencesStateProvider.notifier);

    return preferencesAsync.when(
      data: (preferences) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification Settings'),
          ),
          body: ListView(
            children: [
              // Notification Types Section
              const _SectionHeader('Notification Types'),
              _NotificationToggle(
                title: 'New Messages',
                subtitle: 'Get notified when someone sends you a message',
                value: preferences.newMessage,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'newMessage',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'New Posts',
                subtitle: 'Get notified when people you follow post',
                value: preferences.newPost,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'newPost',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Comments',
                subtitle: 'Get notified when someone comments on your post',
                value: preferences.comment,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'comment',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Followers',
                subtitle: 'Get notified when someone follows you',
                value: preferences.follower,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'follower',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Post Likes',
                subtitle: 'Get notified when someone likes your post',
                value: preferences.likePost,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'likePost',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Post Mentions',
                subtitle: 'Get notified when mentioned in a post',
                value: preferences.mentionPost,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'mentionPost',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Comment Replies',
                subtitle: 'Get notified when someone replies to your comment',
                value: preferences.replyToComment,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'replyToComment',
                    value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Security Alerts',
                subtitle: 'Important: 2FA challenges and device logins',
                value: preferences.twoFactorChallenge,
                onChanged: (value) async {
                  await preferencesNotifier.toggleNotificationType(
                    'twoFactorChallenge',
                    value,
                  );
                },
                isImportant: true,
              ),

              // Sound & Vibration Section
              const _SectionHeader('Sound & Vibration'),
              _NotificationToggle(
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: preferences.enableSound,
                onChanged: (value) async {
                  await preferencesNotifier.updatePreferences(
                    preferences..enableSound = value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Vibration',
                subtitle: 'Vibrate phone for notifications',
                value: preferences.enableVibration,
                onChanged: (value) async {
                  await preferencesNotifier.updatePreferences(
                    preferences..enableVibration = value,
                  );
                },
              ),
              _NotificationToggle(
                title: 'Badge Count',
                subtitle: 'Show notification badge on app icon',
                value: preferences.enableBadge,
                onChanged: (value) async {
                  await preferencesNotifier.updatePreferences(
                    preferences..enableBadge = value,
                  );
                },
              ),

              // Quiet Hours Section
              const _SectionHeader('Quiet Hours'),
              _NotificationToggle(
                title: 'Enable Quiet Hours',
                subtitle: 'Silence notifications during specific times',
                value: preferences.enableQuietHours,
                onChanged: (value) async {
                  if (value && preferences.quietHoursStart == null) {
                    // Set default quiet hours (10 PM to 8 AM)
                    await preferencesNotifier.setQuietHours(
                      const TimeOfDay(hour: 22, minute: 0),
                      const TimeOfDay(hour: 8, minute: 0),
                      true,
                    );
                  } else {
                    await preferencesNotifier.updatePreferences(
                      preferences..enableQuietHours = value,
                    );
                  }
                },
              ),
              if (preferences.enableQuietHours)
                Column(
                  children: [
                    _QuietHoursPicker(
                      title: 'Start Time',
                      time: preferences.quietHoursStart,
                      onTimeChanged: (time) async {
                        if (time != null) {
                          await preferencesNotifier.setQuietHours(
                            time,
                            preferences.quietHoursEnd ??
                                const TimeOfDay(hour: 8, minute: 0),
                            true,
                          );
                        }
                      },
                    ),
                    _QuietHoursPicker(
                      title: 'End Time',
                      time: preferences.quietHoursEnd,
                      onTimeChanged: (time) async {
                        if (time != null) {
                          await preferencesNotifier.setQuietHours(
                            preferences.quietHoursStart ??
                                const TimeOfDay(hour: 22, minute: 0),
                            time,
                            true,
                          );
                        }
                      },
                    ),
                  ],
                ),

              // Actions Section
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset to Defaults'),
                        content: const Text(
                            'Are you sure you want to reset all notification settings?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await preferencesNotifier.updatePreferences(
                        NotificationPreferences(),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                  ),
                  child: const Text('Reset to Defaults'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// Notification toggle widget.
class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isImportant;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: isImportant
          ? const Icon(LucideIcons.shield, color: Colors.red)
          : null,
    );
  }
}

/// Quiet hours time picker.
class _QuietHoursPicker extends StatelessWidget {
  final String title;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const _QuietHoursPicker({
    required this.title,
    required this.time,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        time?.toString() ?? '00:00',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) {
          onTimeChanged(picked);
        }
      },
    );
  }
}

/// Section header widget.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
