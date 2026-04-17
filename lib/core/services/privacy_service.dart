import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivacyService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;

  PrivacyService({
    SupabaseClient? supabase,
    FirebaseAuth? auth,
    FlutterSecureStorage? secureStorage,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _auth = auth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? FlutterSecureStorage();

  /// DPDP Act 2023 - Data Export Compliance
  /// Aggregates all user data linked to their profile and exports it as a JSON file.
  Future<void> exportUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User is not authenticated");

    final Map<String, dynamic> exportData = {};

    try {
      // 1. Fetch Profile
      final profileResponse = await _supabase.from('profiles').select().eq('firebase_uid', uid).maybeSingle();
      if (profileResponse == null) throw Exception("Profile not found");
      
      exportData['profile'] = profileResponse;
      final profileId = profileResponse['id'];

      // 2. Fetch Posts
      final postsResponse = await _supabase.from('posts').select().eq('author_id', profileId);
      exportData['posts'] = postsResponse;

      // 3. Fetch Comments
      try {
        final commentsResponse = await _supabase.from('comments').select().eq('author_id', profileId);
        exportData['comments'] = commentsResponse;
      } catch (_) {
        // Ignored if table doesn't exist
      }

      // 4. Fetch Messages metadata (without exposing encrypted payloads if we don't want to)
      try {
        final messagesResponse = await _supabase.from('messages').select('id, conversation_id, sender_id, created_at, read_at').eq('sender_id', profileId);
        exportData['messages_metadata'] = messagesResponse;
      } catch (_) {
        // Ignored
      }

      // 5. Serialize
      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);

      // 6. Save locally and share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/verasso_my_data_$uid.json');
      await file.writeAsString(jsonString);

      // 7. Share
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Verasso Data Export',
        text: 'Attached is your requested data export in compliance with the DPDP Act 2023.',
      );

    } catch (e) {
      debugPrint("Data Export Failed: \$e");
      rethrow;
    }
  }

  /// DPDP Act 2023 - Right to be Forgotten (Account Deletion)
  /// Wipes remote identifiers, local enclave keys, and permanently deletes Firebase identity.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User is not authenticated");

    final uid = user.uid;

    try {
      // 1. Fetch Profile ID to manually delete relations if necessary
      final profile = await _supabase.from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
      
      if (profile != null) {
        final profileId = profile['id'];

        // Best effort clean-up of known heavy tables client-side before deleting profile.
        // Full constraints might block profiles deletion if CASCADE is missing on relations.
        await _tryDelete('comments', 'author_id', profileId);
        await _tryDelete('post_likes', 'user_id', profileId);
        await _tryDelete('post_saves', 'user_id', profileId);
        await _tryDelete('doubts', 'author_id', profileId);
        await _tryDelete('posts', 'author_id', profileId);
        
        // 2. Delete Supabase Profile
        await _supabase.from('profiles').delete().eq('firebase_uid', uid);
      }

      // 3. Purge Local Secure Storage (Private Keys, Enclave Data)
      await _secureStorage.deleteAll();

      // 4. Delete Firebase Auth Account (Permanent Revocation)
      await user.delete();

    } catch (e) {
      debugPrint("Account Deletion Failed: \$e");
      // If FirebaseAuthRequiresRecentLoginException occurs, it will be thrown to the UI
      // where we should ask the user to sign in again.
      rethrow;
    }
  }
  
  Future<void> _tryDelete(String table, String foreignKey, String profileId) async {
    try {
      await _supabase.from(table).delete().eq(foreignKey, profileId);
    } catch (_) {
       // Silently move on if table is missing or constraints prevent it
    }
  }
}
