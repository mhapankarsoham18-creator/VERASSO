import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'mesh_network_screen.dart'; // To link radar
import '../services/messaging_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final MessagingService? messagingService;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.messagingService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late final MessagingService _messagingService;
  final _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _conversationId;
  String? _peerPublicKey;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _messagingService = widget.messagingService ?? MessagingService();
    _initChat();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      await _messagingService.ensureKeysExist();
      // Notice: Since firebase is used, Supabase.auth.currentUser might be null, but we handled this in ensureKeysExist inside messagingService.
    } catch (e) {
      // Intentionally ignore initial init errors. We'll rely on MessagingService handling.
    }

    try {
      _peerPublicKey = await _messagingService.getPeerPublicKey(widget.peerId);
      _conversationId = await _messagingService.getConversationIdWithPeer(widget.peerId);
      
      // We need our actual Supabase profile ID to distinguish "isMe"
      // Since MessagingService encapsulates this, let me just fetch it by the user_id that matches firebase_uid
      // For now, if we don't have it explicitly, we'll determine isMe by whether the sender_id matches peer_id or not.
      
      if (_conversationId != null) {
        final messagesData = await _messagingService.fetchMessages(_conversationId!);
        await _processMessages(messagesData);
        _subscribeToRealtime();
      }
    } catch (e) {
      debugPrint("Error loading chat: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _subscribeToRealtime() {
    if (_conversationId == null) return;

    _subscription = _messagingService.subscribeToMessages(_conversationId!, (newRecord) async {
       // A new message arrived
       if (_peerPublicKey == null) return;
       
       // Optimization: don't decrypt immediately if we sent it and it's already in the UI. 
       // For this simple version, we'll just process it.
       final isMe = newRecord['sender_id'] != widget.peerId;
       
       String text = "🔒 Encrypted";
       if (isMe) {
          // If we sent it just now, we already added it optimistically to the UI
          // So we skip it unless it's genuinely missing.
          // In a real app we'd map via a nonce or local ID. Let's just find by exact match or skip.
          return; 
       } else {
          text = await _messagingService.decryptMessageRow(newRecord, _peerPublicKey!);
       }

       final createdAt = DateTime.tryParse(newRecord['created_at']) ?? DateTime.now();

       if (mounted) {
         setState(() {
           _messages.add({
             'text': text,
             'isMe': isMe,
             'time': DateFormat.jm().format(createdAt),
             'stamp': createdAt,
           });
           // sort
           _messages.sort((a, b) => (a['stamp'] as DateTime).compareTo(b['stamp'] as DateTime));
         });
         _scrollToBottom();
       }
    });
  }

  Future<void> _processMessages(List<Map<String, dynamic>> data) async {
    final List<Map<String, dynamic>> processed = [];
    
    for (var msg in data) {
       final isMe = msg['sender_id'] != widget.peerId;
       String text = "🔒 Encrypted";
       
       if (_peerPublicKey != null) {
           text = await _messagingService.decryptMessageRow(msg, _peerPublicKey!);
       }
       
       final createdAt = DateTime.tryParse(msg['created_at']) ?? DateTime.now();
       
       processed.add({
         'text': text,
         'isMe': isMe,
         'time': DateFormat.jm().format(createdAt),
         'stamp': createdAt,
       });
    }
    
    if (mounted) {
       setState(() {
         _messages = processed;
       });
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final textToTransmit = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': textToTransmit,
        'isMe': true,
        'time': DateFormat.jm().format(DateTime.now()),
        'stamp': DateTime.now(),
      });
    });
    _scrollToBottom();

    try {
      await _messagingService.sendSecureMessage(widget.peerId, textToTransmit);
      // Wait, if conversation didn't exist before, it does now. 
      // If we didn't have a subscription, we should subscribe.
      if (_conversationId == null) {
         _conversationId = await _messagingService.getConversationIdWithPeer(widget.peerId);
         _peerPublicKey ??= await _messagingService.getPeerPublicKey(widget.peerId);
         _subscribeToRealtime();
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.contains('has not established E2E keys')) {
          errMsg = "Peer has not configured secure messaging yet. Keys missing.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transmission Alert: \$errMsg', 
              style: const TextStyle(color: AppColors.neutralBg, fontWeight: FontWeight.bold)
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        // Remove optimistic bubble on fail
        setState(() {
          _messages.removeLast();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
            const Row(
              children: [
                Icon(Icons.lock, size: 10, color: AppColors.primary),
                SizedBox(width: 4),
                Text('E2E ENCRYPTED', style: TextStyle(fontSize: 8, letterSpacing: 1, color: AppColors.primary, fontWeight: FontWeight.w900)),
              ],
            )
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar, color: AppColors.primary),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshNetworkScreen()));
            },
            tooltip: 'View Mesh Radar',
          ),
        ],
      ),
      body: Column(
        children: [
          // E2E Security Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppColors.shadowLight,
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Messages are end-to-end encrypted and completely unreadable by Verasso servers. Keys are securely backed up locally.',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                         // Avatar
                         NeoPixelBox(
                           padding: 8,
                           backgroundColor: AppColors.shadowLight,
                           child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                         ),
                         const SizedBox(width: 8),
                      ],
                      
                      // Message Bubble
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            NeoPixelBox(
                              padding: 12,
                              backgroundColor: isMe ? AppColors.primary.withValues(alpha: 0.15) : AppColors.shadowLight,
                              child: Text(
                                msg['text'],
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['time'],
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.shadowDark),
                            ),
                          ],
                        ),
                      ),
                      
                      if (isMe) ...[
                         const SizedBox(width: 8),
                         // Avatar
                         NeoPixelBox(
                           padding: 8,
                           backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                           child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                         ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Composition Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.shadowLight,
              border: Border(top: BorderSide(color: AppColors.blockEdge, width: 2)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                         color: AppColors.shadowLight,
                         border: Border.all(color: AppColors.blockEdge, width: 2),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Transmit secure message...',
                          hintStyle: TextStyle(color: AppColors.shadowDark, fontWeight: FontWeight.w600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeoPixelBox(
                    isButton: true,
                    onTap: _sendMessage,
                    padding: 12,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send, color: AppColors.neutralBg, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
