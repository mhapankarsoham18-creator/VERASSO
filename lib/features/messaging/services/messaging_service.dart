import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/validators/input_validator.dart';
import 'crypto_service.dart';
import 'mesh_network_service.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CryptoService _crypto = CryptoService();

  Future<String> _getMyId() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) throw Exception('Not logged in to Supabase');
    return myId;
  }

  /// Ensures profiles.public_key is populated for the current user and private key is in device storage
  Future<void> ensureKeysExist() async {
    final myId = await _getMyId();
    
    // Check if we already have keys locally
    final existingPrivateKey = await _crypto.getStoredPrivateKey(myId);
    final profileData = await _supabase.from('profiles').select('public_key').eq('id', myId).single();
    
    if (existingPrivateKey != null && profileData['public_key'] != null) {
      return; // Keys already established
    }

    // Generate new keys and store private locally
    final keys = await _crypto.generateKeyPairAndStorePrivate(myId);
    
    // Attempt update profiles (public_key)
    await _supabase.from('profiles').update({'public_key': keys['publicKey']}).eq('id', myId);
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
     final dbMessages = await _supabase.from('messages')
         .select('*')
         .eq('conversation_id', conversationId)
         .order('created_at', ascending: true) as List<dynamic>;
         
     final List<Map<String,dynamic>> merged = List<Map<String,dynamic>>.from(dbMessages);
     
     if (Hive.isBoxOpen('mesh_offline_queue')) {
       final offlineBox = Hive.box('mesh_offline_queue');
       final received = List<dynamic>.from(offlineBox.get('received_offline', defaultValue: []));
       final outbox = List<dynamic>.from(offlineBox.get('pending_outbox', defaultValue: []));
       
       for (var item in [...received, ...outbox]) {
         if (item is Map && item['conversationId'] == conversationId) {
           // Does this nonce already exist in DB?
           final existsInDb = merged.any((dbMsg) => dbMsg['nonce'] == item['nonce']);
           if (!existsInDb) {
             merged.add({
               'conversation_id': conversationId,
               'sender_id': item['senderId'],
               'encrypted_payload': item['payload'],
               'nonce': item['nonce'],
               'created_at': DateTime.now().toIso8601String(), // Fallback offline time
               'is_offline': true,
             });
           }
         }
       }
     }
     
     merged.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
     return merged;
  }
  /// Send an encrypted message to a peer. 
  /// Automatically resolves or creates 1-on-1 conversation.
  Future<void> sendSecureMessage(String peerId, String plainText) async {
    await ensureKeysExist();

    final myId = await _getMyId();

    // 1. Fetch own private key from secure storage
    final myPrivateKey = await _crypto.getStoredPrivateKey(myId);
    if (myPrivateKey == null) {
      throw Exception('Missing local private key.');
    }

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

    final validationError = InputValidator.validateSecureMessage(plainText);
    if (validationError != null) throw Exception(validationError);

    final sanitizedMessage = InputValidator.sanitize(plainText);

    // 3. Encrypt payload
    final payload = await _crypto.encryptMessage(
      plaintext: sanitizedMessage,
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

    // 5. Build Mesh Envelope with Signed Metadata
    final senderSig = await MeshNetworkService.signEnvelope(
      senderId: myId,
      nonce: payload['nonce']!,
      targetUserId: peerId,
      privateKeyB64: myPrivateKey,
    );

    // Get our public key to include in envelope for recipient verification
    final myProfile = await _supabase.from('profiles').select('public_key').eq('id', myId).maybeSingle();
    final myPublicKey = myProfile?['public_key'] as String? ?? '';

    final meshPayload = {
      'type': 'offline_message',
      'conversationId': conversationId,
      'senderId': myId,
      'targetUserId': peerId,
      'payload': '${payload['ciphertext']}:${payload['mac']}',
      'nonce': payload['nonce'],
      'ttl': 5,
      'senderSig': senderSig,
      'senderPublicKey': myPublicKey,
    };

    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': myId,
        'encrypted_payload': '${payload['ciphertext']}:${payload['mac']}',
        'nonce': payload['nonce'],
      });
      // If internet works, still broadcast to mesh
      MeshNetworkService().dispatchMeshMessage(meshPayload);
    } catch (e) {
      // Fallback completely to mesh outbox
      await MeshNetworkService().dispatchMeshMessage(meshPayload);
      throw Exception('Cloud unreachable. Transmitted via Encrypted Mesh Relay.');
    }
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
     final myPrivateKey = await _crypto.getStoredPrivateKey(myId);
     if (myPrivateKey == null) {
       return "ERROR: Missing local private key";
     }

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
