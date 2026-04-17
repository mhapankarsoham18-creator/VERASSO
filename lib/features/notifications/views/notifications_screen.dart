import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

/// Notifications screen — shows pending follow requests
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  String? _myProfileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final me = await Supabase.instance.client
        .from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
    if (me != null && mounted) {
      _myProfileId = me['id'];
      await _loadRequests();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequests() async {
    if (_myProfileId == null) return;
    final rows = await Supabase.instance.client
        .from('follows')
        .select('id, follower_id, created_at')
        .eq('following_id', _myProfileId!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    // Fetch profile info for each requester
    final enriched = <Map<String, dynamic>>[];
    for (final row in rows) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name, username, avatar_url, role')
          .eq('id', row['follower_id'])
          .maybeSingle();
      if (profile != null) {
        enriched.add({...row, 'profile': profile});
      }
    }

    if (mounted) {
      setState(() {
        _pendingRequests = enriched;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String followId, int index) async {
    await Supabase.instance.client
        .from('follows')
        .update({'status': 'accepted'})
        .eq('id', followId);
    setState(() => _pendingRequests.removeAt(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Follow request accepted!')));
    }
  }

  Future<void> _rejectRequest(String followId, int index) async {
    await Supabase.instance.client
        .from('follows')
        .delete()
        .eq('id', followId);
    setState(() => _pendingRequests.removeAt(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Follow request rejected.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: _isLoading
          ? Center(child: VerassoLoading())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: context.colors.textSecondary.withAlpha(80)),
                      SizedBox(height: 16),
                      Text('No pending requests', style: TextStyle(color: context.colors.textSecondary, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Follow requests will appear here.', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = _pendingRequests[index];
                    final profile = req['profile'] as Map<String, dynamic>;
                    final name = profile['display_name'] ?? profile['username'] ?? 'Unknown';
                    final avatarUrl = profile['avatar_url'];
                    final role = profile['role'] ?? 'student';

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: NeoPixelBox(
                        padding: 14,
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: context.colors.blockEdge,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.colors.blockEdge, width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatarUrl != null
                                  ? Image.network(avatarUrl, fit: BoxFit.cover)
                                  : Icon(Icons.person, color: context.colors.neutralBg),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 2),
                                  Text(role.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: context.colors.accent, fontWeight: FontWeight.bold)),
                                  Text('wants to follow you', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            NeoPixelBox(
                              padding: 10, isButton: true,
                              onTap: () => _acceptRequest(req['id'], index),
                              child: Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.primary)),
                            ),
                            SizedBox(width: 6),
                            NeoPixelBox(
                              padding: 10, isButton: true,
                              onTap: () => _rejectRequest(req['id'], index),
                              child: Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.error)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
