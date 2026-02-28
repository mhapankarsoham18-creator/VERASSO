import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/security/vault_service.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/presentation/chat_detail_screen.dart';
import 'package:verasso/features/messaging/presentation/vault_screen.dart';

/// Main list of chat conversations.
class ChatsScreen extends ConsumerWidget {
  /// Creates a [ChatsScreen] instance.
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final vaultService = ref.watch(vaultServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Messages'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('BETA',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lock),
            onPressed: () => _openVault(context, ref),
            tooltip: 'Private Vault',
          ),
          IconButton(
            icon: const Icon(LucideIcons.edit),
            onPressed: () => _startNewConversation(context, ref),
          ),
        ],
      ),
      body: LiquidBackground(
        child: conversationsAsync.when(
          data: (conversations) {
            final visible = conversations
                .where((conv) => !vaultService.isChatHidden(conv.id))
                .toList();
            if (currentUserId == null) {
              return const Center(
                  child: EmptyStateWidget(
                title: 'Not signed in',
                message: 'Sign in to view your messages.',
              ));
            }
            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 100),
                child: EmptyStateWidget(
                  title: 'No messages yet',
                  message:
                      'Start a conversation from a profile or when you get a message.',
                  icon: LucideIcons.messageCircle,
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, left: 16, right: 16, bottom: 20),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final conv = visible[index];
                return _ConversationTile(
                  conversation: conv,
                  currentUserId: currentUserId,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        conversationId: conv.id,
                        otherUserId: conv.getOtherParticipantId(currentUserId),
                      ),
                    ),
                  ).then((_) {
                    ref.invalidate(conversationsProvider);
                  }),
                  onLongPress: () => _hideChat(context, ref, conv),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Padding(
            padding: const EdgeInsets.only(top: 100),
            child: AppErrorView(
              title: 'Could not load messages',
              message: err.toString(),
              onRetry: () => ref.invalidate(conversationsProvider),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _hideChat(
      BuildContext context, WidgetRef ref, Conversation conversation) async {
    final vaultService = ref.read(vaultServiceProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide this chat?'),
        content: const Text(
            'This conversation will be moved to your Private Vault and hidden from this list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final authenticated = await vaultService.authenticateAccess();
      if (authenticated) {
        await vaultService.hideChat(conversation.id);
        if (context.mounted) {
          ref.invalidate(conversationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat moved to Private Vault')),
          );
        }
      }
    }
  }

  static Future<void> _openVault(BuildContext context, WidgetRef ref) async {
    final vaultService = ref.read(vaultServiceProvider);
    final authenticated = await vaultService.authenticateAccess();
    if (authenticated && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
      if (context.mounted) ref.invalidate(conversationsProvider);
    }
  }

  static Future<void> _startNewConversation(
      BuildContext context, WidgetRef ref) async {
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId == null) return;

    final controller = TextEditingController();
    final recipientId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter user ID or username',
            prefixIcon: Icon(LucideIcons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );

    if (recipientId == null || !context.mounted) return;

    // Generate a deterministic conversation ID from both user IDs
    final ids = [currentUserId, recipientId]..sort();
    final conversationId = '${ids[0]}_${ids[1]}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId: conversationId,
          otherUserId: recipientId,
        ),
      ),
    ).then((_) {
      if (context.mounted) ref.invalidate(conversationsProvider);
    });
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final hasUnread = conversation.unreadCount > 0;
    final last = conversation.lastMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.withValues(alpha: 0.3),
                  child: Text(
                    otherUserId.length >= 2
                        ? otherUserId.substring(0, 2).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _displayName(otherUserId),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        last != null ? _formatTime(last.sentAt) : '',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              hasUnread ? Colors.greenAccent : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (last != null && last.senderId == currentUserId)
                        _getStatusIcon(last.status),
                      Expanded(
                        child: Text(
                          last != null
                              ? _getMessagePreview(last)
                              : 'No messages',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? Colors.white : Colors.white70,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _displayName(String otherUserId) {
    if (otherUserId.length <= 10) return 'User';
    return 'User ${otherUserId.substring(otherUserId.length - 8)}';
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${time.day}/${time.month}';
  }

  static String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.sticker:
        return '${message.content} Sticker';
      case MessageType.gif:
        return '🎞️ GIF';
    }
  }

  static Widget _getStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white54;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white54;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white54;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 12, color: color),
    );
  }
}
