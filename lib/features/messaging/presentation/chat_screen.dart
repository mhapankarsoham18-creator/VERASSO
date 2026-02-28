import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/exceptions/user_friendly_error_handler.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/presentation/chat_controller.dart';

/// A screen that facilitates a one-on-one chat conversation between users.
class ChatScreen extends ConsumerStatefulWidget {
  /// Unique identifier of the user to chat with.
  final String targetUserId;

  /// Display name of the user to chat with.
  final String targetUserName;

  /// Creates a [ChatScreen].
  const ChatScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(messageRepositoryProvider);
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.targetUserName)),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: repo.getMessages(widget.targetUserId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(UserFriendlyErrorHandler.getDisplayMessage(
                            snapshot.error)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return const Center(
                        child: Text('No messages yet. Say hi!'));
                  }

                  return ListView.builder(
                    reverse:
                        true, // Show latest at bottom (need to reverse list in logic or here)
                    // Messages usually come ordered by created_at ascending.
                    // To show latest at bottom in ListView, usually reverse: true and reversed list.
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Reverse index access
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId != widget.targetUserId;

                      return _EncryptedMessageBubble(
                          message: message, isMe: isMe);
                    },
                  );
                },
              ),
            ),

            // Input Area
            GlassContainer(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: _pickAndSendImage,
                        icon:
                            const Icon(LucideIcons.image, color: Colors.white)),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none),
                      ),
                    ),
                    IconButton(
                      icon: chatState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.send, color: Colors.white),
                      onPressed: chatState.isLoading
                          ? null
                          : () {
                              final text = _textController.text.trim();
                              if (text.isNotEmpty) {
                                ref
                                    .read(chatControllerProvider.notifier)
                                    .sendMessage(widget.targetUserId, text);
                                _textController.clear();
                              }
                            },
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Upload & Send
      // We need to access repo. Ideally this logic belongs in controller, but for now:
      final repo = ref.read(messageRepositoryProvider);
      try {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Uploading image...')));
        final url = await repo.uploadAttachment(file: File(picked.path));

        if (!mounted) return;
        ref
            .read(chatControllerProvider.notifier)
            .sendMessage(widget.targetUserId, url, mediaType: 'image');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _EncryptedMessageBubble extends StatelessWidget {
  /// The message to display in the bubble.
  final Message message;

  /// Whether the message was sent by the current user.
  final bool isMe;

  /// Creates an [_EncryptedMessageBubble] instance.
  const _EncryptedMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Content is already decrypted in the repository
    final content = message.content;
    final mediaType = message.type; // Assuming MessageType enum

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
                : null,
            color: isMe ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft:
                  isMe ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight:
                  isMe ? const Radius.circular(4) : const Radius.circular(20),
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaType == MessageType.image)
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedImage(
                    imageUrl: content,
                    errorWidget: const Icon(LucideIcons.imageOff),
                  ))
            else
              Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat.jm().format(message.sentAt.toLocal()),
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.checkCheck,
                      size: 12, color: Colors.white70)
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}
