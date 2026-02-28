import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/messaging/services/encryption_service.dart';

/// A scalable UI component for displaying encrypted group messages.
class GroupChatScreen extends ConsumerStatefulWidget {
  /// Unique identifier for the group.
  final String groupId;

  /// Display name of the group.
  final String groupName;

  /// Creates a [GroupChatScreen] instance.
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type an encrypted message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.send),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == ref.read(currentUserProvider)?.id;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg['sender_name'] ?? 'Unknown',
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            Text(
              msg['decrypted_content'] ?? '[Encrypted]',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      // In a real scenario, we'd fetch actual group member IDs
      final receiverIds = ['user1', 'user2'];

      final encryptedData = await encryptionService.encryptGroupMessage(
        content,
        receiverIds,
      );

      // Simulate sending and receiving
      setState(() {
        _messages.insert(0, {
          'sender_id': ref.read(currentUserProvider)?.id,
          'sender_name': 'Me',
          'decrypted_content': content,
          'encrypted_content': encryptedData['content'],
          'timestamp': DateTime.now().toIso8601String(),
        });
        _messageController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
