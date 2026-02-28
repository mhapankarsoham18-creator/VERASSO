import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'biometric_auth_service.dart';

/// Provider for the [VaultService] instance.
final vaultServiceProvider = Provider((ref) => VaultService());

/// Service for managing a secure, biometric-protected vault for sensitive data.
///
/// It allows users to hide or unhide specific conversations and ensures that
/// access to the vault is protected by biometric authentication with a
/// timed session to prevent unauthorized access.
class VaultService {
  static const String _vaultBoxName = 'hidden_vault';
  static const String _hiddenChatsKey = 'hidden_chat_ids';
  static const Duration _sessionDuration = Duration(minutes: 5);

  final BiometricAuthService _biometricAuth = BiometricAuthService();
  DateTime? _lastAuthenticated;

  /// Authenticate user to access the vault or hide/unhide chats
  Future<bool> authenticateAccess() async {
    final result = await _biometricAuth.authenticate(
      reason: 'Please authenticate to manage your Private Vault',
    );
    if (result.success) {
      _lastAuthenticated = DateTime.now();
    }
    return result.success;
  }

  /// Get all hidden chat IDs
  Future<List<String>> getHiddenChatIds() async {
    if (!_isSessionValid() && !await authenticateAccess()) return [];

    final box = Hive.box(_vaultBoxName);
    return List<String>.from(
        box.get(_hiddenChatsKey, defaultValue: <String>[]));
  }

  /// Hide a conversation
  Future<void> hideChat(String conversationId) async {
    if (!_isSessionValid() && !await authenticateAccess()) return;

    final box = Hive.box(_vaultBoxName);
    final List<String> hiddenIds =
        List<String>.from(box.get(_hiddenChatsKey, defaultValue: <String>[]));

    if (!hiddenIds.contains(conversationId)) {
      hiddenIds.add(conversationId);
      await box.put(_hiddenChatsKey, hiddenIds);
    }
  }

  /// Check if a conversation is hidden
  bool isChatHidden(String conversationId) {
    // We allow checking hidden status without session to filter the chat list
    // BUT we should not allow reading vault contents without session.
    final box = Hive.box(_vaultBoxName);
    final List<String> hiddenIds =
        List<String>.from(box.get(_hiddenChatsKey, defaultValue: <String>[]));
    return hiddenIds.contains(conversationId);
  }

  /// Unhide a conversation
  Future<void> unhideChat(String conversationId) async {
    if (!_isSessionValid() && !await authenticateAccess()) return;

    final box = Hive.box(_vaultBoxName);
    final List<String> hiddenIds =
        List<String>.from(box.get(_hiddenChatsKey, defaultValue: <String>[]));

    if (hiddenIds.contains(conversationId)) {
      hiddenIds.remove(conversationId);
      await box.put(_hiddenChatsKey, hiddenIds);
    }
  }

  bool _isSessionValid() {
    if (_lastAuthenticated == null) return false;
    return DateTime.now().difference(_lastAuthenticated!) < _sessionDuration;
  }
}
