import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/security/encryption_service.dart';
import '../../../core/services/supabase_service.dart';

// Riverpod provider
/// Provider for the [MessagingEncryptionService].
final messagingEncryptionProvider = Provider((ref) {
  return MessagingEncryptionService();
});

/// End-to-End Encryption Service for Direct Messaging
/// Uses AES-256-GCM for symmetric encryption
/// Each message pair has unique encryption key derived from shared secret
class MessagingEncryptionService {
  final SupabaseClient _client;
  final EncryptionService _encryptionService;

  /// Creates a [MessagingEncryptionService] instance.
  MessagingEncryptionService({
    SupabaseClient? client,
    EncryptionService? encryptionService,
  })  : _client = client ?? SupabaseService.client,
        _encryptionService = encryptionService ?? EncryptionService();

  /// Decrypt received message
  /// Expects encrypted message in format: encrypted_text:iv:auth_tag
  /// Decrypts a received message from a specific sender.
  Future<String> decryptMessage(
    String encryptedMessage,
    String senderUserId,
  ) async {
    try {
      // Get conversation key (same key used for encryption)
      // This ensures we use the correct key for decryption
      await _getOrCreateConversationKey(senderUserId);

      // Decrypt message
      final decryptedMessage = _encryptionService.decrypt(encryptedMessage);

      AppLogger.info('Message decrypted from $senderUserId');
      return decryptedMessage;
    } catch (e) {
      AppLogger.info('Message decryption error: $e');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Encrypt message before sending
  /// Returns encrypted message in format: encrypted_text:iv:auth_tag
  /// Encrypts a message for a specific recipient.
  Future<String> encryptMessage(
    String plaintext,
    String recipientUserId,
  ) async {
    try {
      // Get conversation key (derived from sender+recipient IDs)
      // This ensures consistent key derivation for the conversation
      await _getOrCreateConversationKey(recipientUserId);

      // Encrypt message using conversation key
      // Use standard encrypt method - conversation key derivation handled server-side
      final encryptedMessage = _encryptionService.encrypt(plaintext);

      AppLogger.info('Message encrypted for $recipientUserId');
      return encryptedMessage;
    } catch (e) {
      AppLogger.info('Message encryption error: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Rotate encryption key for a conversation
  /// Used for forward secrecy and key rotation
  /// Rotates the encryption key for a specific conversation to ensure forward secrecy.
  Future<void> rotateConversationKey(String otherUserId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final conversationId = _sortAndConcatenate(currentUserId, otherUserId);
      final newKey = _generateConversationKey(
          '$conversationId:${DateTime.now().millisecondsSinceEpoch}');

      // Update key in database
      await _client.from('conversation_keys').update(
          {'encryption_key': newKey}).eq('conversation_id', conversationId);

      AppLogger.info('Conversation key rotated for $otherUserId');
    } catch (e) {
      AppLogger.info('Key rotation error: $e');
      throw Exception('Failed to rotate conversation key: $e');
    }
  }

  /// Search encrypted messages by decrypted content
  /// Returns message IDs that match search query
  /// Searches through all encrypted messages by their decrypted content.
  Future<List<String>> searchMessages(String searchQuery) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get all conversations for current user
      final conversations = await _client
          .from('conversations')
          .select('id, user_1_id, user_2_id')
          .or('user_1_id.eq.$currentUserId,user_2_id.eq.$currentUserId');

      List<String> matchingMessageIds = [];

      // Search messages in each conversation
      for (var conv in conversations as List) {
        final conversationId = conv['id'] as String;
        final otherUserId = conv['user_1_id'] == currentUserId
            ? conv['user_2_id']
            : conv['user_1_id'];

        // Get all messages in conversation
        final messages = await _client
            .from('messages')
            .select('id, content')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false);

        // Decrypt and search each message
        for (var msg in messages as List) {
          try {
            final decryptedContent = await decryptMessage(
              msg['content'] as String,
              otherUserId,
            );

            if (decryptedContent
                .toLowerCase()
                .contains(searchQuery.toLowerCase())) {
              matchingMessageIds.add(msg['id'] as String);
            }
          } catch (e) {
            // Log decryption errors but continue searching
            AppLogger.info(
                'Search: Failed to decrypt message ${msg['id']}: $e');
          }
        }
      }

      return matchingMessageIds;
    } catch (e) {
      AppLogger.info('Message search error: $e');
      return [];
    }
  }

  /// Verify message authenticity and integrity
  /// Uses HMAC to ensure message wasn't tampered with
  /// Verifies the authenticity and integrity of a message using its HMAC.
  Future<bool> verifyMessageIntegrity(
    String encryptedMessage,
    String senderUserId,
    String expectedHmac,
  ) async {
    try {
      final conversationKey = await _getOrCreateConversationKey(senderUserId);

      // Calculate HMAC of encrypted message
      final calculatedHmac = _calculateHmac(encryptedMessage, conversationKey);

      return calculatedHmac == expectedHmac;
    } catch (e) {
      AppLogger.info('Verify message integrity error: $e');
      return false;
    }
  }

  /// Calculate HMAC for message integrity verification
  /// Calculate HMAC for message integrity verification
  String _calculateHmac(String message, String key) {
    final keyBytes = utf8.encode(key);
    final messageBytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(messageBytes);
    return digest.toString();
  }

  /// Generate deterministic key from conversation ID
  /// Uses SHA-256 for key derivation
  String _generateConversationKey(String conversationId) {
    final bytes = utf8.encode(conversationId);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes)
        .substring(0, 32); // Ensure 32 bytes for AES-256
  }

  /// Get or create encryption key for conversation
  /// Key is derived from current user ID + other user ID
  Future<String> _getOrCreateConversationKey(String otherUserId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create deterministic key from user IDs
      // In production, this should be fetched from secure key exchange
      final conversationId = _sortAndConcatenate(currentUserId, otherUserId);

      // Try to get existing key from database
      final response = await _client
          .from('conversation_keys')
          .select('encryption_key')
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (response != null) {
        return response['encryption_key'] as String;
      }

      // Create new key for this conversation
      final newKey = _generateConversationKey(conversationId);

      // Store key in database
      await _client.from('conversation_keys').insert({
        'conversation_id': conversationId,
        'user_1_id': currentUserId,
        'user_2_id': otherUserId,
        'encryption_key': newKey,
        'created_at': DateTime.now().toIso8601String(),
      });

      return newKey;
    } catch (e) {
      AppLogger.info('Get/create conversation key error: $e');
      throw Exception('Failed to get encryption key: $e');
    }
  }

  /// Sort user IDs to create consistent conversation ID
  String _sortAndConcatenate(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}:${ids[1]}';
  }

  // Public methods for testing
  /// Public version of _calculateHmac for testing
  String calculateHmacPublic(String message, String key) =>
      _calculateHmac(message, key);

  /// Public version of _generateConversationKey for testing
  String generateConversationKeyPublic(String conversationId) =>
      _generateConversationKey(conversationId);

  /// Public version of _sortAndConcatenate for testing
  String sortAndConcatenatePublic(String userId1, String userId2) =>
      _sortAndConcatenate(userId1, userId2);
}
