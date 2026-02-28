import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Repository for managing user privacy actions and data exports via Supabase.
class PrivacyRepository {
  final SupabaseClient _client;

  /// Creates a [PrivacyRepository] with an optional [SupabaseClient].
  PrivacyRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Delete user account and all associated data
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Call RPC to cleanup all user data (posts, profile, etc.)
    await _client.rpc('delete_user_account');

    // Sign out (Supabase admin usually handles actual auth deletion via dashboard or function)
    await _client.auth.signOut();
  }

  /// Export all user data as JSON (GDPR Right to Portability)
  Future<String> exportUserData() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = <String, dynamic>{
      'profile': null,
      'posts': [],
      'comments': [],
      'sessions': [],
      'export_date': DateTime.now().toIso8601String(),
    };

    // Fetch Profile
    final profile =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    data['profile'] = profile;

    // Fetch Posts
    final posts = await _client.from('posts').select().eq('user_id', user.id);
    data['posts'] = posts;

    // Fetch Comments
    final comments =
        await _client.from('comments').select().eq('user_id', user.id);
    data['comments'] = comments;

    // Fetch Sessions (Security Data)
    final sessions =
        await _client.from('auth_sessions').select().eq('user_id', user.id);
    data['sessions'] = sessions;

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
