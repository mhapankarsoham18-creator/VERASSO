import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../../../core/services/ai_service.dart';

/// A screen for interacting with the Verasso AI educational assistant.
class AIAssistantScreen extends ConsumerStatefulWidget {
  /// Creates an [AIAssistantScreen] instance.
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

/// A widget representing a single message in the AI chat.
class ChatBubble extends StatelessWidget {
  /// The chat message data model.
  final ChatMessage message;

  /// Creates a [ChatBubble] instance.
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white10,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: Border.all(
              color: message.isUser
                  ? Colors.cyanAccent.withValues(alpha: 0.3)
                  : Colors.white12),
        ),
        child: Text(
          message.text,
          style:
              const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

/// Data model for a single message in the AI assistant conversation.
class ChatMessage {
  /// The text content of the message.
  final String text;

  /// Whether the message was sent by the user (vs the AI).
  final bool isUser;

  /// Creates a [ChatMessage] instance.
  ChatMessage({required this.text, required this.isUser});
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hi there! I'm Cosmos 🤖. I can help you find courses, plan your study, or explain simulations. What's on your mind?",
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.bot, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('Cosmos AI'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                    top: 100, bottom: 20, left: 16, right: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ask Cosmos...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, color: Colors.cyanAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 4, backgroundColor: Colors.white54)
                .animate(onPlay: (c) => c.repeat())
                .scale(duration: 600.ms)
                .fadeIn(),
            const SizedBox(width: 4),
            const CircleAvatar(radius: 4, backgroundColor: Colors.white54)
                .animate(onPlay: (c) => c.repeat(), delay: 200.ms)
                .scale(duration: 600.ms)
                .fadeIn(),
            const SizedBox(width: 4),
            const CircleAvatar(radius: 4, backgroundColor: Colors.white54)
                .animate(onPlay: (c) => c.repeat(), delay: 400.ms)
                .scale(duration: 600.ms)
                .fadeIn(),
          ],
        ),
      ),
    );
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

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await ref.read(aiServiceProvider).sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
              text:
                  "I'm having trouble connecting to the cosmos right now. Please try again later.",
              isUser: false));
          _isTyping = false;
        });
      }
    }
  }
}
