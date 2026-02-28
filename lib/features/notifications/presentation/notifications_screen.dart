import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/notification_service.dart';
import '../models/notification_model.dart';

// Stream provider for notifications list
// Stream provider for notifications list
/// Provider for the list of notifications, automatically disposed.
final notificationsListProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotificationsStream();
});

/// Main screen for viewing all user notifications.
class NotificationsScreen extends ConsumerWidget {
  /// Creates a [NotificationsScreen].
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: GlassContainer(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bellOff,
                          size: 48, color: Colors.white54),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, bottom: 20, left: 16, right: 16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationTile(notification: notification),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(notificationsListProvider),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.redAccent.withValues(alpha: 0.5),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) {
        // Typically we would delete, but for now just mark read or ignore
        ref.read(notificationServiceProvider).markAsRead(notification.id);
      },
      child: GlassContainer(
        color: isUnread ? Colors.blueAccent.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.all(16),
        border: isUnread
            ? Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.white10, width: 1.5),
        child: InkWell(
          onTap: () {
            if (isUnread) {
              ref.read(notificationServiceProvider).markAsRead(notification.id);
            }
            // Navigate based on type
            final data = notification.data;
            if (data != null && data.containsKey('route')) {
              context.push(data['route']);
            } else if (notification.type == NotificationType.storyLike ||
                notification.type == NotificationType.storyComment) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stories feature coming soon!')),
              );
            } else if (notification.type == NotificationType.levelUp) {
              context.push('/'); // Go to home/profile
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.createdAt),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.storyLike:
        icon = LucideIcons.heart;
        color = Colors.pinkAccent;
        break;
      case NotificationType.storyComment:
        icon = LucideIcons.messageCircle;
        color = Colors.blueAccent;
        break;
      case NotificationType.achievement:
        icon = LucideIcons.trophy;
        color = Colors.amber;
        break;
      case NotificationType.levelUp:
        icon = LucideIcons.zap;
        color = Colors.purpleAccent;
        break;
      case NotificationType.leaderboard:
        icon = LucideIcons.trendingUp;
        color = Colors.greenAccent;
        break;
      case NotificationType.system:
      default:
        icon = LucideIcons.bell;
        color = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
