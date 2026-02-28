import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/exceptions/user_friendly_error_handler.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/security/shield_service.dart';
import 'package:verasso/core/theme/app_colors.dart';
import 'package:verasso/core/ui/error_dialog.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/secrecy_filter.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/data/presence_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/presentation/chat_controller.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';

/// Detailed view of a chat conversation with a specific user.
class ChatDetailScreen extends ConsumerStatefulWidget {
  /// Unique identifier for the conversation.
  final String conversationId;

  /// Unique identifier for the other participant.
  final String otherUserId;

  /// Creates a [ChatDetailScreen] instance.
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final PresenceRepository _presenceRepo = PresenceRepository();
  bool _otherUserOnline = false;
  final bool _otherUserTyping = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<List<Message>>? _messagesSubscription;

  List<Message> _messages = [];
  bool _showMediaOptions = false;
  // bool _isShieldEnabled = false; // Now handled by global PrivacySettings

  @override
  Widget build(BuildContext context) {
    // Listen to chat errors
    ref.listen(chatControllerProvider, (previous, next) {
      if (next.hasError) {
        ErrorDialog.show(
          context,
          title: 'Message Error',
          message: UserFriendlyErrorHandler.getDisplayMessage(next.error),
          onRetry: () {
            // Retry will happen when user sends next message
          },
        );
      }
    });

    final privacySettings = ref.watch(privacySettingsProvider);
    final isShieldedGlobally = privacySettings.autoShieldChats;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.withValues(alpha: 0.3),
              child: const Text('U', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ${widget.otherUserId}',
                    style: const TextStyle(fontSize: 14)),
                Text(
                  _otherUserTyping
                      ? 'Typing...'
                      : (_otherUserOnline ? 'Online' : 'Offline'),
                  style: TextStyle(
                    fontSize: 10,
                    color: _otherUserTyping
                        ? Colors.blueAccent
                        : (_otherUserOnline
                            ? Colors.greenAccent
                            : AppColors.white34),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(
              isShieldedGlobally ? LucideIcons.shieldCheck : LucideIcons.shield,
              color: isShieldedGlobally ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () {
              ref
                  .read(privacySettingsProvider.notifier)
                  .setAutoShieldChats(!isShieldedGlobally);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isShieldedGlobally
                      ? 'Privacy Shield Deactivated'
                      : 'Privacy Shield Activated'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Toggle Privacy Shield',
          ),
          IconButton(icon: const Icon(LucideIcons.phone), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.video), onPressed: () {}),
          IconButton(
              icon: const Icon(LucideIcons.moreVertical), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.purple.shade900.withValues(alpha: 0.3)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final myId = ref.read(currentUserProvider)?.id;
                  final isMe = myId != null && message.senderId == myId;
                  return _buildMessageBubble(message, isMe);
                },
              ),
            ),

            // Media options
            if (_showMediaOptions) _buildMediaOptions(),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _presenceRepo.leavePresence();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTypingChanged);
    _subscribeToMessages();
    _initPresence();
  }

  Widget _buildInputArea() {
    return GlassContainer(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_showMediaOptions ? Icons.close : LucideIcons.plus),
            onPressed: () =>
                setState(() => _showMediaOptions = !_showMediaOptions),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMediaOptions() {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMediaButton(
              LucideIcons.image, 'Photo', () => _pickMedia(MessageType.image)),
          _buildMediaButton(
              LucideIcons.video, 'Video', () => _pickMedia(MessageType.video)),
          _buildMediaButton(
              LucideIcons.mic, 'Audio', () => _pickMedia(MessageType.audio)),
          _buildMediaButton(
              LucideIcons.smile, 'Sticker', () => _showStickers()),
          _buildMediaButton(Icons.gif, 'GIF', () => _showGifs()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(12),
              color: isMe
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.sentAt),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white54),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _getStatusIcon(message.status, size: 12),
                      ],
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

  Widget _buildMessageContent(Message message) {
    final shieldService = ref.read(shieldServiceProvider);
    final privacySettings = ref.read(privacySettingsProvider);
    final isShielded = privacySettings.autoShieldChats || message.isShielded;

    switch (message.type) {
      case MessageType.text:
        String text = message.content;
        if (isShielded) {
          text = shieldService.scrambleText(text);
        }
        return Text(text,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'));

      case MessageType.image:
        return SecrecyFilter(
          isContentVisible: !isShielded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade800,
                  child: const Icon(LucideIcons.image,
                      size: 64, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 4),
              const Text('📷 Image',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        );

      case MessageType.video:
        return SecrecyFilter(
          isContentVisible: !isShielded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey.shade800,
                  child: const Icon(LucideIcons.playCircle,
                      size: 64, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 4),
              const Text('🎥 Video',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        );

      case MessageType.audio:
        return SecrecyFilter(
          isContentVisible: !isShielded,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.play, color: Colors.white),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('0:30', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );

      case MessageType.sticker:
        if (isShielded) {
          return const Text('✨',
              style:
                  TextStyle(fontSize: 48)); // Obfuscate stickers with a sparkle
        }
        return Text(message.content, style: const TextStyle(fontSize: 48));

      case MessageType.gif:
        return SecrecyFilter(
          isContentVisible: !isShielded,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.stickyNote,
                size: 64, color: Colors.white54),
          ),
        );
    }
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month} ${time.hour}:${time.minute}';
  }

  Widget _getStatusIcon(MessageStatus status, {double size = 16}) {
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

    return Icon(icon, size: size, color: color);
  }

  void _initPresence() {
    final myId = ref.read(currentUserProvider)?.id;
    if (myId != null) {
      _presenceRepo.joinPresence(myId, widget.conversationId, (onlineUsers) {
        if (mounted) {
          setState(() =>
              _otherUserOnline = onlineUsers.contains(widget.otherUserId));
        }
      });
    }
  }

  void _onTypingChanged() {
    final myId = ref.read(currentUserProvider)?.id;
    if (myId == null) return;

    if (_messageController.text.isNotEmpty) {
      _presenceRepo.sendTyping(widget.conversationId, myId, true);
    } else {
      _presenceRepo.sendTyping(widget.conversationId, myId, false);
    }
  }

  Future<void> _pickMedia(MessageType type) async {
    setState(() => _showMediaOptions = false);

    try {
      if (type == MessageType.image) {
        final image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          _sendMediaMessage(image.path, type);
        }
      } else if (type == MessageType.video) {
        final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          _sendMediaMessage(video.path, type);
        }
      } else if (type == MessageType.audio) {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.audio);
        if (result != null) {
          _sendMediaMessage(result.files.first.path!, type);
        }
      }
    } catch (e) {
      AppLogger.error('Error picking media', error: e);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMediaMessage(String path, MessageType type) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      final publicUrl = await repo.uploadAttachment(file: File(path));
      _sendTextMessage(publicUrl, type);
    } catch (e) {
      AppLogger.error('Error uploading media', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload media')),
        );
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _sendTextMessage(_messageController.text, MessageType.text);
    _messageController.clear();
  }

  void _sendTextMessage(String content, MessageType type) {
    final myId = ref.read(currentUserProvider)?.id;
    if (myId == null) return;

    final mediaType = type.name;
    final newMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: myId,
      content: content,
      type: type,
      status: MessageStatus.sending,
      sentAt: DateTime.now(),
    );

    setState(() => _messages = [..._messages, newMessage]);
    _scrollToBottom();

    ref
        .read(chatControllerProvider.notifier)
        .sendMessage(
          widget.otherUserId,
          content,
          mediaType: mediaType,
        )
        .then((_) {
      if (mounted) _scrollToBottom();
    });
  }

  void _showGifs() {
    setState(() => _showMediaOptions = false);
    // Real GIF picker logic (simplified simulation using a selection of URLs)
    final gifUrls = [
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6JmVwPXYxX2ludGVybmFsX2dpZl9hZGRfcmVjZW50X2lkJmN0PWc/3o7TKDkDbIDJieKbVm/giphy.gif',
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6JmVwPXYxX2ludGVybmFsX2dpZl9hZGRfcmVjZW50X2lkJmN0PWc/l41lI4bYyO0mZpY7m/giphy.gif',
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6JmVwPXYxX2ludGVybmFsX2dpZl9hZGRfcmVjZW50X2lkJmN0PWc/3o7TKVUn7iM8FMEU24/giphy.gif',
      'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6ZDZ6JmVwPXYxX2ludGVybmFsX2dpZl9hZGRfcmVjZW50X2lkJmN0PWc/3o7TKQHq3V8rF2T6VO/giphy.gif',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a GIF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gifUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _sendTextMessage(gifUrls[index], MessageType.gif);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(gifUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStickers() {
    setState(() => _showMediaOptions = false);
    // Show sticker picker (simplified)
    final stickers = ['👍', '❤️', '😂', '🎉', '🔥', '✨', '💯', '🚀'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stickers.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _sendTextMessage(stickers[index], MessageType.sticker);
              },
              child: Text(stickers[index],
                  style: const TextStyle(fontSize: 48),
                  textAlign: TextAlign.center),
            );
          },
        ),
      ),
    );
  }

  void _subscribeToMessages() {
    final repo = ref.read(messageRepositoryProvider);
    final myId = ref.read(currentUserProvider)?.id;
    _messagesSubscription =
        repo.getMessages(widget.otherUserId).listen((messages) {
      if (mounted) {
        setState(() => _messages = messages);
        _scrollToBottom();

        // Mark incoming unread messages as read
        if (myId != null) {
          for (final msg in messages) {
            if (msg.senderId != myId && msg.status != MessageStatus.read) {
              repo.markAsRead(msg.id);
            }
          }
        }
      }
    });
  }
}
