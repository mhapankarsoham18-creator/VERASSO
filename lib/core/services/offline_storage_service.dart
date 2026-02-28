import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../security/encryption_service.dart';

/// Provider for the [OfflineStorageService] instance.
final offlineStorageServiceProvider = Provider<OfflineStorageService>((ref) {
  return OfflineStorageService();
});

/// Service for managing local offline data storage using Hive.
///
/// Handles:
/// - Encrypted local storage (Vault)
/// - Caching of network requests
/// - Pending action queue for offline-first capabilities
class OfflineStorageService {
  /// Name of the Hive box used for storing pending offline actions.
  static const String pendingActionsBox = 'pending_actions';

  /// Name of the Hive box used for general application data caching.
  static const String cacheBox = 'app_cache';

  /// Name of the Hive box used for encrypted sensitive data storage.
  static const String hiddenVaultBox = 'hidden_vault';

  /// Name of the Hive box used for tracking file upload chunks.
  static const String fileChunksBox = 'file_chunks';

  // --- General Cache ---

  /// Caches [value] under [key] in the default cache box.
  Future<void> cacheData(String key, dynamic value) async {
    final box = Hive.box(cacheBox);
    await box.put(key, {
      'data': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Removes all pending actions from the queue.
  Future<void> clearAllPendingActions() async {
    final box = Hive.box(pendingActionsBox);
    await box.clear();
  }

  /// Removes all chunks for a specific file.
  Future<void> clearFileChunks(String fileId) async {
    final box = Hive.box(fileChunksBox);
    final keysToDelete =
        box.keys.where((k) => (k as String).startsWith('${fileId}_'));
    await box.deleteAll(keysToDelete);
  }

  /// Deletes a specific pending action by its [key].
  Future<void> deleteAction(dynamic key) async {
    final box = Hive.box(pendingActionsBox);
    await box.delete(key);
  }

  /// Retrieves cached data for [key], optionally checking [expiration].
  dynamic getCachedData(String key, {Duration? expiration}) {
    final box = Hive.box(cacheBox);
    final entry = box.get(key);

    if (entry == null) return null;

    if (expiration != null) {
      final timestamp = DateTime.parse(entry['timestamp']);
      if (DateTime.now().difference(timestamp) > expiration) {
        box.delete(key);
        return null; // Expired
      }
    }

    return entry['data'];
  }

  /// Retrieves a specific file chunk.
  List<int>? getFileChunk(String fileId, int chunkIndex) {
    final box = Hive.box(fileChunksBox);
    return box.get('${fileId}_$chunkIndex') as List<int>?;
  }

  // --- Pending Actions (Queue) ---

  /// Returns a map of all currently pending actions.
  Map<dynamic, dynamic> getPendingActionsMap() {
    final box = Hive.box(pendingActionsBox);
    return box.toMap();
  }

  /// Initializes Hive and opens application boxes using [encryptionService].
  Future<void> initialize(EncryptionService encryptionService) async {
    await Hive.initFlutter();

    final encryptionKey = await encryptionService.getHiveKey();
    final cipher = HiveAesCipher(encryptionKey);

    await Hive.openBox(pendingActionsBox, encryptionCipher: cipher);
    await Hive.openBox(cacheBox, encryptionCipher: cipher);
    await Hive.openBox(hiddenVaultBox, encryptionCipher: cipher);
    await Hive.openBox(fileChunksBox, encryptionCipher: cipher);
  }

  // --- Chunked File Tracking ---

  /// Adds a new [actionType] with its [data] to the pending queue.
  ///
  /// Optionally accepts an [id] to prevent duplicate actions for the same entity.
  /// If an action with the same [id] exists, it will only be replaced if the
  /// new one is newer based on [timestamp].
  Future<void> queueAction(String actionType, Map<String, dynamic> data,
      {String? id}) async {
    final box = Hive.box(pendingActionsBox);
    final timestamp = DateTime.now().toIso8601String();

    if (id != null) {
      // Conflict Resolution: Check if this entity already has a pending action
      final existingKey = box.keys.firstWhere(
        (k) => (box.get(k) as Map)['id'] == id,
        orElse: () => null,
      );

      if (existingKey != null) {
        final existing = Map<String, dynamic>.from(box.get(existingKey));
        final existingTime = DateTime.parse(existing['timestamp']);
        if (DateTime.now().isBefore(existingTime)) {
          return; // Existing is newer, discard this one
        }
        await box.delete(existingKey); // Remove older one to replace
      }
    }

    final action = {
      'id': id,
      'type': actionType,
      'data': data,
      'timestamp': timestamp,
      'retries': 0,
      'status': 'pending',
    };
    await box.add(action);
  }

  /// Tracks a file part for multi-part upload.
  Future<void> saveFileChunk(
      String fileId, int chunkIndex, List<int> data) async {
    final box = Hive.box(fileChunksBox);
    await box.put('${fileId}_$chunkIndex', data);
  }

  /// Updates the retry [count] for a specific pending action.
  Future<void> updateActionRetry(dynamic key, int retries) async {
    final box = Hive.box(pendingActionsBox);
    final action = Map<String, dynamic>.from(box.get(key));
    action['retries'] = retries;
    await box.put(key, action);
  }
}
