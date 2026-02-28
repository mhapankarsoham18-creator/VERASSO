import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/ui/glass_container.dart';
import '../../../core/ui/liquid_background.dart';
import '../data/notification_service.dart';
import '../models/notification_model.dart';

/// A dedicated screen for the notification center, providing a centralized view of all alerts.
class NotificationCenterScreen extends ConsumerWidget {
  /// Creates a [NotificationCenterScreen].
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await notificationService.markAllAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: LiquidBackground(
        child: StreamBuilder<List<NotificationModel>>(
          stream: notificationService.getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.bell, size: 64, color: Colors.white38),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, left: 16, right: 16, bottom: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () async {
                    if (!notification.isRead) {
                      await notificationService.markAsRead(notification.id);
                    }
                    if (!context.mounted) return;
                    _handleNotificationTap(context, notification);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Handles the tap event on a notification.
  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Navigate to relevant screen based on notification type
    final data = notification.data;

    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        // Navigate to post detail
        if (data?['post_id'] != null) {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: data['post_id'])));
        }
        break;
      case NotificationType.follow:
        // Navigate to user profile
        if (data?['user_id'] != null) {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: data['user_id'])));
        }
        break;
      case NotificationType.message:
        // Navigate to chat
        if (data?['conversation_id'] != null) {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: data['conversation_id'])));
        }
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon based on type
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
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
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.redAccent;
      case NotificationType.comment:
        return Colors.blueAccent;
      case NotificationType.follow:
        return Colors.greenAccent;
      case NotificationType.mention:
        return Colors.orangeAccent;
      case NotificationType.message:
        return Colors.purpleAccent;
      case NotificationType.achievement:
        return Colors.yellowAccent;
      case NotificationType.levelUp:
        return Colors.cyanAccent;
      default:
        return Colors.white70;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return LucideIcons.heart;
      case NotificationType.comment:
        return LucideIcons.messageCircle;
      case NotificationType.follow:
        return LucideIcons.userPlus;
      case NotificationType.mention:
        return LucideIcons.atSign;
      case NotificationType.message:
        return LucideIcons.mail;
      case NotificationType.achievement:
        return LucideIcons.award;
      case NotificationType.levelUp:
        return LucideIcons.trendingUp;
      default:
        return LucideIcons.bell;
    }
  }
}
