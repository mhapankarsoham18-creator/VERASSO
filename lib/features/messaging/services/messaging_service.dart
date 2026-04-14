import 'package:supabase_flutter/supabase_flutter.dart';
import 'crypto_service.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CryptoService _crypto = CryptoService();

  Future<String> _getMyId() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in to Supabase');
    return myId;
  }

  /// Ensures user_keys and profiles.public_key are populated for the current user
  Future<void> ensureKeysExist() async {
    final myId = await _getMyId();
    
    // Check if we already have keys in the database
    final existingUserKeys = await _supabase.from('user_keys').select('private_key').eq('user_id', myId).maybeSingle();
    final profileData = await _supabase.from('profiles').select('public_key').eq('id', myId).single();
    
    if (existingUserKeys != null && profileData['public_key'] != null) {
      return; // Keys already established
    }

    // Generate new keys
    final keys = await _crypto.generateKeyPair();
    
    // Attempt update profiles (public_key)
    await _supabase.from('profiles').update({'public_key': keys['publicKey']}).eq('id', myId);
    
    // Upsert into user_keys (private_key)
    await _supabase.from('user_keys').upsert({
      'user_id': myId,
      'private_key': keys['privateKey'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getConversationIdWithPeer(String peerId) async {
     final existingConversations = await _supabase.rpc(
      'get_private_conversation', 
      params: {'other_user_id': peerId}
    );
    if (existingConversations != null && (existingConversations as List).isNotEmpty) {
       return existingConversations[0]['id'] as String;
    }
    return null;
  }

  Future<String?> getPeerPublicKey(String peerId) async {
     final peerResp = await _supabase.from('profiles').select('public_key').eq('id', peerId).maybeSingle();
     return peerResp?['public_key'] as String?;
  }

  Future<List<Map<String,dynamic>>> fetchMessages(String conversationId) async {
     return await _supabase.from('messages')
         .select('*')
         .eq('conversation_id', conversationId)
         .order('created_at', ascending: true);
  }

  /// Send an encrypted message to a peer. 
  /// Automatically resolves or creates 1-on-1 conversation.
  Future<void> sendSecureMessage(String peerId, String plainText) async {
    await ensureKeysExist();

    final myId = await _getMyId();

    // 1. Fetch own private key from user_keys table
    final myKeyResp = await _supabase
        .from('user_keys')
        .select('private_key')
        .eq('user_id', myId)
        .single();
    final myPrivateKey = myKeyResp['private_key'] as String;

    // 2. Fetch peer's public key from profiles table
    final peerResp = await _supabase
        .from('profiles')
        .select('public_key')
        .eq('id', peerId)
        .single();
    final peerPublicKey = peerResp['public_key'] as String?;
    
    if (peerPublicKey == null) {
       throw Exception('Peer has not established E2E keys yet.');
    }

    // 3. Encrypt payload
    final payload = await _crypto.encryptMessage(
      plaintext: plainText,
      myPrivateKeyB64: myPrivateKey,
      peerPublicKeyB64: peerPublicKey,
    );

    // 4. Resolve Conversation (or create if missing)
    final existingConversations = await _supabase.rpc(
      'get_private_conversation', 
      params: {'other_user_id': peerId}
    );
    
    String conversationId;
    if (existingConversations != null && (existingConversations as List).isNotEmpty) {
       conversationId = existingConversations[0]['id'];
    } else {
       // Create new conversation
       final convRes = await _supabase.from('conversations').insert({ 'is_group': false }).select('id').single();
       conversationId = convRes['id'];
       // Add participants
       await _supabase.from('conversation_participants').insert([
         {'conversation_id': conversationId, 'user_id': myId},
         {'conversation_id': conversationId, 'user_id': peerId},
       ]);
    }

    // 5. Send encrypted row
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'encrypted_payload': '${payload['ciphertext']}:${payload['mac']}',
      'nonce': payload['nonce'],
    });
  }

  /// Subscribe to new messages for a specific conversation
  RealtimeChannel subscribeToMessages(String conversationId, void Function(Map<String, dynamic>) onMessage) {
    return _supabase.channel('public:messages:conversation_id=$conversationId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, 
          column: 'conversation_id', 
          value: conversationId,
        ),
        callback: (payload) {
          onMessage(payload.newRecord);
        },
      )
      .subscribe();
  }

  /// Decrypt a message row using Diffie-Hellman symmetric property.
  Future<String> decryptMessageRow(Map<String, dynamic> messageRow, String peerPublicKey) async {
     final myId = await _getMyId();
     final myKeyResp = await _supabase.from('user_keys').select('private_key').eq('user_id', myId).single();
     final myPrivateKey = myKeyResp['private_key'] as String;

     final encryptedCombined = messageRow['encrypted_payload'] as String;
     final nonce = messageRow['nonce'] as String;
     
     final parts = encryptedCombined.split(':');
     if (parts.length != 2) return "ERROR: Invalid ciphertext format";
     
     final ciphertext = parts[0];
     final mac = parts[1];

     try {
       return await _crypto.decryptMessage(
         ciphertextB64: ciphertext,
         nonceB64: nonce,
         macB64: mac,
         myPrivateKeyB64: myPrivateKey,
         peerPublicKeyB64: peerPublicKey,
       );
     } catch (e) {
       return "ERROR: Could not decrypt message";
     }
  }
}
