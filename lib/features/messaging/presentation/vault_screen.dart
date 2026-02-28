import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/security/vault_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/presentation/chat_detail_screen.dart';

/// Secure vault for hidden and sensitive chat conversations.
class VaultScreen extends ConsumerStatefulWidget {
  /// Creates a [VaultScreen] instance.
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  @override
  Widget build(BuildContext context) {
    final vaultService = ref.watch(vaultServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.shieldCheck, size: 20, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Private Vault'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ref.watch(conversationsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.redAccent))),
              data: (allConversations) {
                return FutureBuilder<List<String>>(
                  future: vaultService.getHiddenChatIds(),
                  builder: (context, snapshot) {
                    final List<String> hiddenIds = snapshot.data ?? [];
                    final hiddenConversations = allConversations
                        .where((c) => hiddenIds.contains(c.id))
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.only(
                          top: 100, left: 16, right: 16, bottom: 20),
                      children: [
                        const GlassContainer(
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Icon(LucideIcons.info, color: Colors.blueAccent),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Chats in this vault are hidden from your main message list. Long-press to restore.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (hiddenConversations.isEmpty)
                          const Center(
                            child: GlassContainer(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(LucideIcons.lock,
                                      size: 64, color: Colors.white24),
                                  SizedBox(height: 16),
                                  Text('Your vault is empty',
                                      style: TextStyle(color: Colors.white38)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...hiddenConversations
                              .map((conv) => _buildConversationCard(conv)),
                      ],
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final otherUserId = conversation.getOtherParticipantId('user123');

    return GestureDetector(
      onLongPress: () => _unhideChat(conversation),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conversation.id,
              otherUserId: otherUserId,
            ),
          ),
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
              child: const Icon(LucideIcons.user, color: Colors.greenAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User $otherUserId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Encrypted Content',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Future<void> _unhideChat(Conversation conversation) async {
    final vaultService = ref.read(vaultServiceProvider);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unhide this chat?'),
        content: const Text(
            'This conversation will be moved back to your main message list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('Unhide', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authenticated = await vaultService.authenticateAccess();
      if (authenticated) {
        await vaultService.unhideChat(conversation.id);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat restored to main list')),
          );
        }
      }
    }
  }
}
