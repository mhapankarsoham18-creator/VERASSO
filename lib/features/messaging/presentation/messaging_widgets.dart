import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/message_read_receipt_service.dart';

/// Encryption Status Badge
class EncryptionStatusBadge extends StatelessWidget {
  /// Whether the content is end-to-end encrypted.
  final bool isEncrypted;

  /// Whether the content has been verified via HMAC.
  final bool isVerified;

  /// Creates an [EncryptionStatusBadge] instance.
  const EncryptionStatusBadge({
    super.key,
    this.isEncrypted = true,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEncrypted) {
      return const Tooltip(
        message: 'Message is not encrypted',
        child: Icon(
          Icons.lock_open,
          color: Colors.orange,
          size: 16,
        ),
      );
    }

    return Tooltip(
      message: isVerified
          ? 'End-to-end encrypted and verified'
          : 'End-to-end encrypted',
      child: Icon(
        isVerified ? Icons.verified : Icons.lock,
        color: Colors.green,
        size: 16,
      ),
    );
  }
}

/// Message Bubble with Read Receipt Status
class MessageBubble extends ConsumerWidget {
  /// ID of the message to display.
  final String messageId;

  /// Decrypted text content or media label.
  final String content;

  /// Whether the message was sent by the current authenticated user.
  final bool isFromCurrentUser;

  /// Timestamp when the message was sent.
  final DateTime sentTime;

  /// Callback when the bubble is tapped.
  final VoidCallback onTap;

  /// Whether the message is shown as end-to-end encrypted.
  final bool isEncrypted;

  /// Creates a [MessageBubble] instance.
  const MessageBubble({
    super.key,
    required this.messageId,
    required this.content,
    required this.isFromCurrentUser,
    required this.sentTime,
    required this.onTap,
    this.isEncrypted = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 4,
          horizontal: isFromCurrentUser ? 0 : 0,
        ),
        child: Row(
          mainAxisAlignment: isFromCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isFromCurrentUser) const SizedBox(width: 8),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: isFromCurrentUser
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isFromCurrentUser ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(sentTime),
                          style: TextStyle(
                            color: isFromCurrentUser
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (isFromCurrentUser) ...[
                          const SizedBox(width: 4),
                          _buildReadReceiptIcon(ref, messageId),
                        ],
                        if (isEncrypted) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: isFromCurrentUser
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isFromCurrentUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReadReceiptIcon(WidgetRef ref, String messageId) {
    return FutureBuilder<MessageReadStatus?>(
      future:
          ref.read(messageReadReceiptProvider).getMessageReadStatus(messageId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.isRead) {
            return const Icon(LucideIcons.checkCheck,
                size: 12, color: Colors.white70);
          }
        }
        return const Icon(LucideIcons.check, size: 12, color: Colors.white70);
      },
    );
  }
}

/// Message Statistics Panel
class MessageStatisticsPanel extends ConsumerWidget {
  /// The conversation ID to fetch statistics for.
  final String conversationId;

  /// Creates a [MessageStatisticsPanel] instance.
  const MessageStatisticsPanel({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(messageReadReceiptProvider);

    return FutureBuilder<ConversationReadStats?>(
      future: service.getConversationReadStats(conversationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message Statistics',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              _StatRow('Total Messages', stats.totalMessages.toString()),
              _StatRow('Read', stats.readMessages.toString()),
              _StatRow('Unread', stats.unreadMessages.toString()),
              _StatRow(
                'Read Rate',
                '${stats.readPercentage.toStringAsFixed(1)}%',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Read Receipt Status Indicator
class ReadReceiptIndicator extends ConsumerWidget {
  /// The message ID to track.
  final String messageId;

  /// Color for unread status.
  final Color unreadColor;

  /// Color for read status.
  final Color readColor;

  /// Creates a [ReadReceiptIndicator] instance.
  const ReadReceiptIndicator({
    super.key,
    required this.messageId,
    this.unreadColor = Colors.grey,
    this.readColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MessageReadStatus?>(
      future:
          ref.read(messageReadReceiptProvider).getMessageReadStatus(messageId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final status = snapshot.data!;
          if (status.isRead) {
            return Tooltip(
              message: 'Read at ${DateFormat('HH:mm').format(status.readAt!)}',
              child: Icon(
                Icons.done_all,
                color: readColor,
                size: 16,
              ),
            );
          }
        }
        return Icon(
          Icons.done,
          color: unreadColor,
          size: 16,
        );
      },
    );
  }
}

/// Typing Indicator (shows when user is typing)
class TypingIndicator extends StatefulWidget {
  /// Whether the user is currently typing.
  final bool isTyping;

  /// Display name of the typing user.
  final String username;

  /// Creates a [TypingIndicator] instance.
  const TypingIndicator({
    super.key,
    required this.isTyping,
    required this.username,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

/// Unread Badge - Shows unread message count
class UnreadBadge extends ConsumerWidget {
  /// The conversation ID to track unread messages for.
  final String conversationId;

  /// The badge background color.
  final Color? backgroundColor;

  /// The text style for the unread count.
  final TextStyle? textStyle;

  /// Creates an [UnreadBadge] instance.
  const UnreadBadge({
    super.key,
    required this.conversationId,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(conversationUnreadCountProvider(conversationId));

    return unreadCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.red,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6),
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.red,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Text('${widget.username} is typing'),
          const SizedBox(width: 4),
          ...[0, 1, 2].map(
            (index) => ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.2).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    0.3 + index * 0.1,
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping && !oldWidget.isTyping) {
      _animationController.repeat();
    } else if (!widget.isTyping && oldWidget.isTyping) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (widget.isTyping) {
      _animationController.repeat();
    }
  }
}
