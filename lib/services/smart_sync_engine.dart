// Smart Sync Engine with Exponential Backoff and Delta Sync
// Handles intelligent synchronization of offline changes with cloud backend

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import 'indexdb_sync_service.dart';

/// Engine for handling intelligent synchronization of offline changes with the cloud backend.
/// Supports exponential backoff and delta-based synchronization.
class SmartSyncEngine {
  static const int _maxRetries = 5;
  static const int _initialBackoffMs = 1000; // 1 second
  static const int _maxBackoffMs = 300000; // 5 minutes
  /// The service for local IndexDB operations.
  final IndexDbSyncService indexDbService;

  /// The base URL for the sync API.
  final String baseUrl;

  /// The unique identifier for the user.
  final String userId;

  final Connectivity _connectivity = Connectivity();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();

  final _syncErrorController = StreamController<SyncError>.broadcast();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _retryTimer;
  int _consecutiveFailures = 0;

  bool _isSyncing = false;
  final Set<String> _documentsInProgress = {};

  /// Creates a [SmartSyncEngine] instance.
  SmartSyncEngine({
    required this.indexDbService,
    required this.baseUrl,
    required this.userId,
  }) {
    _monitorConnectivity();
  }

  /// Whether a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// A stream of synchronization errors.
  Stream<SyncError> get syncErrorStream => _syncErrorController.stream;

  /// A stream of synchronization progress updates.
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;

  /// Disposes of the engine and cancels all active subscriptions and timers.
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
    _retryTimer?.cancel();
    await _syncProgressController.close();
    await _syncErrorController.close();
  }

  /// Triggers an immediate synchronization process for all unsynced documents.
  Future<void> forceSyncNow() async {
    _consecutiveFailures = 0;
    _retryTimer?.cancel();
    await _performSync();
  }

  /// Temporarily pauses any scheduled synchronization operations.
  void pauseSync() {
    _retryTimer?.cancel();
  }

  /// Manually resolve a conflict
  Future<void> resolveConflict({
    required String documentId,
    required bool useLocalVersion,
  }) async {
    try {
      final doc = await indexDbService.getDocument(documentId);
      if (doc == null) return;

      if (useLocalVersion) {
        // Send local version to server, overwriting remote
        await _sendDelta(
          documentId: documentId,
          delta: await _calculateDelta(documentId, 0),
          vectorClock: doc.vectorClock,
        );
      }

      // Mark as synced after resolution
      await indexDbService.markDocumentSynced(documentId);
    } catch (e, stack) {
      _emitError('Conflict resolution failed', e.toString(), e, stack);
    }
  }

  /// Resumes the regular background synchronization process.
  void resumeSync() {
    _scheduleSync();
  }

  /// Calculate exponential backoff with jitter
  int _calculateBackoff(int failureCount) {
    if (failureCount >= _maxRetries) return _maxBackoffMs;

    final baseBackoff = _initialBackoffMs * pow(2, failureCount).toInt();
    final jitter = Random().nextInt((baseBackoff * 0.1).toInt());

    return min(baseBackoff + jitter, _maxBackoffMs);
  }

  /// Calculate delta - only send changes since last sync
  Future<Map<String, dynamic>> _calculateDelta(
    String documentId,
    int lastSyncedVersion,
  ) async {
    final doc = await indexDbService.getDocument(documentId);
    if (doc == null) throw Exception('Document not found');

    return {
      'documentId': documentId,
      'lastSyncedVersion': lastSyncedVersion,
      'currentVersion': doc.vectorClock.toMap(),
      'content': doc.content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  void _emitError(String title, String message,
      [dynamic error, StackTrace? stack]) {
    AppLogger.error('$title: $message', error: error);
    if (error != null) {
      SentryService.captureException(error, stackTrace: stack);
    }
    _syncErrorController.sink.add(
      SyncError(
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _emitProgress(String message, int percentComplete) {
    _syncProgressController.sink.add(
      SyncProgress(
        message: message,
        percentComplete: percentComplete,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Handle conflicts between local and remote versions
  Future<void> _handleConflict(
    String documentId,
    Map<String, dynamic> remoteData,
  ) async {
    try {
      final localDoc = await indexDbService.getDocument(documentId);
      if (localDoc == null) return;

      final remoteVectorClock = VectorClock.fromMap(
        remoteData['vectorClock'] as Map<String, dynamic>,
      );

      // Detect if it's a true conflict
      final conflict = await indexDbService.detectConflict(
        documentId: documentId,
        localVersion: localDoc.vectorClock,
        remoteVersion: remoteVectorClock,
      );

      if (conflict != null) {
        // Emit conflict for user resolution
        indexDbService.emitConflict(conflict);

        // Store conflict info for later resolution
        await _storeConflictMetadata(documentId, conflict);
      } else {
        // Not a real conflict - just update to remote version
        await indexDbService.storeDocument(
          documentId: documentId,
          userId: userId,
          documentType: localDoc.documentType,
          content: remoteData['content'] as Map<String, dynamic>,
          vectorClock: remoteVectorClock,
        );
      }
    } catch (e, stack) {
      _emitError('Conflict handling failed', e.toString(), e, stack);
    }
  }

  /// Monitor connectivity changes and sync when online
  void _monitorConnectivity() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        _emitProgress('Connected', 0);
        _scheduleSync();
      } else {
        _emitProgress('Offline', 0);
        _retryTimer?.cancel();
      }
    });
  }

  /// Perform full sync of unsynced documents
  Future<void> _performSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _emitProgress('Starting sync', 0);

    try {
      final unsyncedDocs = await indexDbService.getUnsyncedDocuments();

      if (unsyncedDocs.isEmpty) {
        _emitProgress('All documents synced', 100);
        _consecutiveFailures = 0;
        _isSyncing = false;
        return;
      }

      int completed = 0;
      for (final doc in unsyncedDocs) {
        if (_documentsInProgress.contains(doc.id)) continue;

        _documentsInProgress.add(doc.id);
        try {
          await _syncDocument(doc);
          completed++;
          _emitProgress('Syncing: $completed/${unsyncedDocs.length}',
              ((completed / unsyncedDocs.length) * 100).toInt());
        } catch (e, stack) {
          _emitError('Failed to sync ${doc.id}', e.toString(), e, stack);
        } finally {
          _documentsInProgress.remove(doc.id);
        }
      }

      _consecutiveFailures = 0;
      _emitProgress('Sync completed', 100);
    } catch (e, stack) {
      _consecutiveFailures++;
      _emitError('Sync failed', e.toString(), e, stack);
      _scheduleSync(); // Retry with backoff
    } finally {
      _isSyncing = false;
    }
  }

  /// Schedule sync with exponential backoff
  void _scheduleSync() {
    if (_isSyncing || _consecutiveFailures >= _maxRetries) {
      return;
    }

    _retryTimer?.cancel();

    final backoffMs = _calculateBackoff(_consecutiveFailures);
    _emitProgress(
        'Sync scheduled in ${(backoffMs / 1000).toStringAsFixed(1)}s', 0);

    _retryTimer = Timer(Duration(milliseconds: backoffMs), () {
      _performSync();
    });
  }

  /// Send delta to server
  Future<http.Response> _sendDelta({
    required String documentId,
    required Map<String, dynamic> delta,
    required VectorClock vectorClock,
  }) async {
    try {
      return await http.post(
        Uri.parse('$baseUrl/api/sync/delta'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userId',
          'X-Client-Version': '2.0.0',
        },
        body: jsonEncode({
          'documentId': documentId,
          'delta': delta,
          'vectorClock': vectorClock.toMap(),
        }),
      );
    } catch (e, stack) {
      AppLogger.error('Send delta error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      _consecutiveFailures++;
      rethrow;
    }
  }

  /// Store conflict metadata for manual resolution
  Future<void> _storeConflictMetadata(
    String documentId,
    SyncConflict conflict,
  ) async {
    // In production, store in a separate 'conflicts' table
    // For now, emit the conflict for UI handling
    _emitError(
      'Conflict detected in $documentId',
      'Local and remote versions are concurrent',
    );
  }

  /// Sync a single document - Delta Sync Strategy
  Future<void> _syncDocument(StoredDocument document) async {
    final syncStatus = await indexDbService.getSyncStatus(document.id);
    if (syncStatus == null) return;

    try {
      // Get delta (only changes since last sync)
      final delta = await _calculateDelta(
        document.id,
        syncStatus.lastSyncedVersion ?? 0,
      );

      // Send delta to server
      final response = await _sendDelta(
        documentId: document.id,
        delta: delta,
        vectorClock: document.vectorClock,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Sync timeout'),
      );

      // Handle server response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Check for conflicts
        if (responseData['hasConflict'] == true) {
          await _handleConflict(
            document.id,
            responseData['remoteVersion'] as Map<String, dynamic>,
          );
        } else {
          // Mark as synced
          await indexDbService.markDocumentSynced(document.id);
        }
      } else if (response.statusCode == 409) {
        // Conflict detected on server
        await _handleConflict(
          document.id,
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception(
            'Sync failed: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      _consecutiveFailures++;
      throw Exception('Sync request timed out');
    }
  }
}

/// Sync error information
/// Represents an error that occurred during synchronization.
class SyncError {
  /// The title or brief summary of the error.
  final String title;

  /// A detailed message describing the error.
  final String message;

  /// The time at which the error occurred.
  final DateTime timestamp;

  /// Creates a new [SyncError] instance.
  SyncError({
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

/// Sync progress information
/// Represents the progress of a synchronization operation.
class SyncProgress {
  /// A message describing the current sync status.
  final String message;

  /// The percentage of the sync operation that has been completed (0-100).
  final int percentComplete;

  /// The time at which this progress update was generated.
  final DateTime timestamp;

  /// Creates a new [SyncProgress] instance.
  SyncProgress({
    required this.message,
    required this.percentComplete,
    required this.timestamp,
  });
}
