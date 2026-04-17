import 'package:flutter/material.dart';
import 'package:verasso/core/widgets/verasso_snackbar.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'chat_screen.dart';
import 'mesh_radar_screen.dart';
import '../services/mesh_network_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Single query: fetch all my conversations with participant + profile data joined
      final results = await _supabase
          .from('conversation_participants')
          .select('conversation_id, conversations(id, updated_at, name, is_group)')
          .eq('user_id', myId)
          .order('conversation_id', ascending: false)
          .timeout(Duration(seconds: 8));

      if (results.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Collect all conversation IDs
      final convIds = <String>[];
      final convMap = <String, Map<String, dynamic>>{};
      for (final row in results) {
        final conv = row['conversations'];
        if (conv == null) continue;
        final convId = conv['id'] as String;
        convIds.add(convId);
        convMap[convId] = conv;
      }

      if (convIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Batch query: fetch ALL participants for ALL my conversations in one call
      final allParticipants = await _supabase
          .from('conversation_participants')
          .select('conversation_id, user_id, profiles(display_name, avatar_url)')
          .inFilter('conversation_id', convIds)
          .neq('user_id', myId)
          .timeout(Duration(seconds: 8));

      // Index peers by conversation_id
      final peersByConv = <String, Map<String, dynamic>>{};
      for (final p in allParticipants) {
        final cid = p['conversation_id'] as String;
        if (!peersByConv.containsKey(cid)) {
          peersByConv[cid] = p;
        }
      }

      // Build result list — no more per-conversation queries
      final List<Map<String, dynamic>> enriched = [];
      for (final convId in convIds) {
        final conv = convMap[convId]!;
        final peer = peersByConv[convId];
        final profile = peer?['profiles'];

        enriched.add({
          'convId': convId,
          'peerName': profile?['display_name'] ?? 'Unknown',
          'peerId': peer?['user_id'] ?? '',
          'lastTime': '',
          'isGroup': conv['is_group'] ?? false,
        });
      }

      if (mounted) {
        setState(() {
          _conversations = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        VerassoSnackbar.show(context, message: 'Failed to load conversations: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'TRANSMISSIONS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 18),
            ),
            ListenableBuilder(
              listenable: MeshNetworkService(),
              builder: (context, _) {
                final mesh = MeshNetworkService();
                if (mesh.state == MeshNodeState.connected) {
                   return Text('[MESH SYNCING]', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.blueAccent, fontWeight: FontWeight.w900));
                }
                if (mesh.state == MeshNodeState.disconnected) {
                   return Text('[MESH OFFLINE]', style: TextStyle(fontSize: 8, letterSpacing: 1, color: context.colors.error, fontWeight: FontWeight.w900));
                }
                return Text('[MESH ACTIVE]', style: TextStyle(fontSize: 8, letterSpacing: 1, color: context.colors.primary, fontWeight: FontWeight.w900));
              }
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.radar, color: context.colors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeshRadarScreen()));
            },
            tooltip: 'Mesh Radar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: VerassoLoading())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: NeoPixelBox(
        padding: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: context.colors.textSecondary.withValues(alpha: 0.5)),
            SizedBox(height: 16),
            Text(
              'NO TRANSMISSIONS YET',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation from a user profile\nor wait for incoming mesh packets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return NeoPixelBox(
          isButton: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  peerId: conv['peerId'],
                  peerName: conv['peerName'],
                ),
              ),
            );
          },
          padding: 16,
          child: Row(
            children: [
              // Avatar Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: context.colors.blockEdge, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.person, color: context.colors.primary, size: 24),
                ),
              ),
              SizedBox(width: 16),
              // Name and E2E badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (conv['peerName'] as String).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 14,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.lock, size: 10, color: context.colors.primary),
                        SizedBox(width: 4),
                        Text(
                          'ENCRYPTED',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Timestamp
              if ((conv['lastTime'] as String).isNotEmpty)
                Text(
                  conv['lastTime'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.colors.shadowDark,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
