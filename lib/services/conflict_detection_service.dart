// Advanced Conflict Detection and Resolution Service
// Implements CRDT-like strategies with user-configurable resolution policies

import 'dart:async';

import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import 'indexdb_sync_service.dart';

/// Automatic resolution result
class AutoResolutionResult {
  /// The resolved content of the document.
  final Map<String, dynamic> resolvedContent;

  /// The strategy used for resolution.
  final ResolutionStrategy strategy;

  /// The ID of the user whose version was chosen as the winner.
  final String winnerUserId;

  /// The confidence score of the automatic resolution (0.0 to 1.0).
  final double confidence; // 0.0 to 1.0

  /// A map indicating the source of each merged field.
  final Map<String, String> mergedFields; // field -> source

  /// Creates an [AutoResolutionResult] instance.
  AutoResolutionResult({
    required this.resolvedContent,
    required this.strategy,
    required this.winnerUserId,
    required this.confidence,
    required this.mergedFields,
  });

  /// Whether this result should be applied automatically based on confidence.
  bool get shouldApplyAutomatically => confidence >= 0.7;
}

/// Conflict analysis result
class ConflictAnalysis {
  /// The unique identifier for the document.
  final String documentId;

  /// The local version of the document (vector clock).
  final VectorClock localVersion;

  /// The remote version of the document (vector clock).
  final VectorClock remoteVersion;

  /// The local content of the document.
  final Map<String, dynamic> localContent;

  /// The remote content of the document.
  final Map<String, dynamic> remoteContent;

  /// The ID of the local user.
  final String localUserId;

  /// The ID of the remote user.
  final String remoteUserId;

  /// The timestamp of the conflict detection.
  final DateTime timestamp;

  /// The calculated severity of the conflict.
  final ConflictSeverity severity;

  /// Creates a [ConflictAnalysis] instance.
  ConflictAnalysis({
    required this.documentId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localContent,
    required this.remoteContent,
    required this.localUserId,
    required this.remoteUserId,
    required this.timestamp,
    required this.severity,
  });
}

/// Service for detecting and managing conflicts during document synchronization.
class ConflictDetectionService {
  /// The service used for local data persistence and sync operations.
  final IndexDbSyncService indexDbService;

  /// Stream of conflict events detected during synchronization.
  final _conflictStreamController = StreamController<ConflictEvent>.broadcast();

  /// Stream of resolution events applied to documents.
  final _resolutionStreamController =
      StreamController<ResolutionEvent>.broadcast();

  /// Creates a [ConflictDetectionService] instance.
  ConflictDetectionService({required this.indexDbService});

  /// A stream of [ConflictEvent]s emitted when conflicts are detected.
  Stream<ConflictEvent> get conflictStream => _conflictStreamController.stream;

  /// A stream of [ResolutionEvent]s emitted when conflicts are resolved.
  Stream<ResolutionEvent> get resolutionStream =>
      _resolutionStreamController.stream;

  /// Detect conflicts when applying remote changes
  Future<ConflictAnalysis?> analyzeConflict({
    required String documentId,
    required VectorClock localVersion,
    required VectorClock remoteVersion,
    required Map<String, dynamic> localContent,
    required Map<String, dynamic> remoteContent,
    required String localUserId,
    required String remoteUserId,
  }) async {
    // Check if versions are concurrent
    if (localVersion.happensBefore(remoteVersion)) {
      return null; // Remote is newer, no conflict
    }

    if (remoteVersion.happensBefore(localVersion)) {
      return null; // Local is newer, no conflict
    }

    // Versions are concurrent - true conflict detected
    final conflict = ConflictAnalysis(
      documentId: documentId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localContent: localContent,
      remoteContent: remoteContent,
      localUserId: localUserId,
      remoteUserId: remoteUserId,
      timestamp: DateTime.now(),
      severity: _calculateSeverity(localContent, remoteContent),
    );

    // Emit conflict for monitoring/logging
    _conflictStreamController.sink.add(
      ConflictEvent(
        documentId: documentId,
        conflict: conflict,
        detectedAt: DateTime.now(),
      ),
    );

    return conflict;
  }

  /// Apply resolution and update document
  Future<void> applyResolution({
    required String documentId,
    required Map<String, dynamic> resolvedContent,
    required VectorClock newVectorClock,
    required String resolutionNote,
  }) async {
    try {
      await indexDbService.storeDocument(
        documentId: documentId,
        userId: 'system',
        documentType: 'resolved-document',
        content: resolvedContent,
        vectorClock: newVectorClock,
      );

      _resolutionStreamController.sink.add(
        ResolutionEvent(
          documentId: documentId,
          resolvedAt: DateTime.now(),
          resolutionNote: resolutionNote,
          success: true,
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Conflict resolution application failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      _resolutionStreamController.sink.add(
        ResolutionEvent(
          documentId: documentId,
          resolvedAt: DateTime.now(),
          resolutionNote: 'Failed: $e',
          success: false,
        ),
      );
    }
  }

  /// Attempt automatic resolution using multiple strategies
  Future<AutoResolutionResult?> attemptAutoResolution({
    required ConflictAnalysis conflict,
    ResolutionStrategy strategy = ResolutionStrategy.lastWriteWins,
  }) async {
    try {
      switch (strategy) {
        case ResolutionStrategy.lastWriteWins:
          return _resolveLastWriteWins(conflict);

        case ResolutionStrategy.firstWriteWins:
          return _resolveFirstWriteWins(conflict);

        case ResolutionStrategy.largerVersionWins:
          return _resolveLargerVersionWins(conflict);

        case ResolutionStrategy.fieldLevelMerge:
          return _resolveFieldLevelMerge(conflict);

        case ResolutionStrategy.requiresManualResolution:
          return null; // User must resolve
      }
    } catch (e, stack) {
      AppLogger.error('Auto-resolution calculation failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return null;
    }
  }

  /// Check if conflict can be automatically resolved
  bool canAutoResolve(ConflictAnalysis conflict) {
    // Simple heuristic: if changes are in different fields, can merge
    if (conflict.severity == ConflictSeverity.low) {
      return true;
    }

    // If only one user has changes, can resolve
    if (conflict.localContent.keys.isEmpty ||
        conflict.remoteContent.keys.isEmpty) {
      return true;
    }

    return false;
  }

  /// Disposes of the stream controllers and releases resources.
  Future<void> dispose() async {
    await _conflictStreamController.close();
    await _resolutionStreamController.close();
  }

  /// Get conflict history for a document
  Future<List<ConflictEvent>> getConflictHistory(String documentId) async {
    // In production, query from conflict_history table
    return [];
  }

  ConflictSeverity _calculateSeverity(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    int changedFields = 0;

    final allKeys = {...local.keys, ...remote.keys};
    for (final key in allKeys) {
      if (local[key] != remote[key]) {
        changedFields++;
      }
    }

    if (changedFields == 0) return ConflictSeverity.none;
    if (changedFields <= 2) return ConflictSeverity.low;
    if (changedFields <= 5) return ConflictSeverity.medium;
    return ConflictSeverity.high;
  }

  DateTime _extractTimestamp(Map<String, dynamic> content) {
    if (content.containsKey('timestamp')) {
      final ts = content['timestamp'];
      if (ts is int) {
        return DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        return DateTime.parse(ts);
      }
    }
    return DateTime.now();
  }

  /// Field-Level Merge: Merge non-conflicting fields
  AutoResolutionResult _resolveFieldLevelMerge(ConflictAnalysis conflict) {
    final merged = Map<String, dynamic>.from(conflict.localContent);
    final mergedFields = <String, String>{};

    // For each field in remote, check if it conflicts
    for (final remoteKey in (conflict.remoteContent.keys.toList())) {
      if (!conflict.localContent.containsKey(remoteKey)) {
        // Field only in remote, safe to merge
        merged[remoteKey] = conflict.remoteContent[remoteKey];
        mergedFields[remoteKey] = conflict.remoteUserId;
      } else if (conflict.localContent[remoteKey] ==
          conflict.remoteContent[remoteKey]) {
        // Same value, safe to keep
        continue;
      } else {
        // Different values for same field - use local for now
        // (field-level conflict - would need sub-field analysis)
        mergedFields[remoteKey] = 'conflict';
      }
    }

    return AutoResolutionResult(
      resolvedContent: merged,
      strategy: ResolutionStrategy.fieldLevelMerge,
      winnerUserId: 'merged_${conflict.localUserId}_${conflict.remoteUserId}',
      confidence: mergedFields.isEmpty ? 0.95 : 0.5,
      mergedFields: mergedFields,
    );
  }

  /// First-Write-Wins: Keep the first version
  AutoResolutionResult _resolveFirstWriteWins(ConflictAnalysis conflict) {
    final localTime = _extractTimestamp(conflict.localContent);
    final remoteTime = _extractTimestamp(conflict.remoteContent);

    late Map<String, dynamic> winner;
    late String winnerUserId;

    if (localTime.isBefore(remoteTime)) {
      winner = conflict.localContent;
      winnerUserId = conflict.localUserId;
    } else {
      winner = conflict.remoteContent;
      winnerUserId = conflict.remoteUserId;
    }

    return AutoResolutionResult(
      resolvedContent: winner,
      strategy: ResolutionStrategy.firstWriteWins,
      winnerUserId: winnerUserId,
      confidence: 0.7,
      mergedFields: {},
    );
  }

  /// Larger-Version-Wins: Use version number magnitude
  AutoResolutionResult _resolveLargerVersionWins(ConflictAnalysis conflict) {
    final localMagnitude = conflict.localVersion.magnitude();
    final remoteMagnitude = conflict.remoteVersion.magnitude();

    late Map<String, dynamic> winner;
    late String winnerUserId;

    if (localMagnitude >= remoteMagnitude) {
      winner = conflict.localContent;
      winnerUserId = conflict.localUserId;
    } else {
      winner = conflict.remoteContent;
      winnerUserId = conflict.remoteUserId;
    }

    return AutoResolutionResult(
      resolvedContent: winner,
      strategy: ResolutionStrategy.largerVersionWins,
      winnerUserId: winnerUserId,
      confidence: 0.6,
      mergedFields: {},
    );
  }

  /// Last-Write-Wins: Use timestamp to determine winner
  AutoResolutionResult _resolveLastWriteWins(ConflictAnalysis conflict) {
    final localTime = _extractTimestamp(conflict.localContent);
    final remoteTime = _extractTimestamp(conflict.remoteContent);

    late Map<String, dynamic> winner;
    late String winnerUserId;

    if (localTime.isAfter(remoteTime)) {
      winner = conflict.localContent;
      winnerUserId = conflict.localUserId;
    } else {
      winner = conflict.remoteContent;
      winnerUserId = conflict.remoteUserId;
    }

    return AutoResolutionResult(
      resolvedContent: winner,
      strategy: ResolutionStrategy.lastWriteWins,
      winnerUserId: winnerUserId,
      confidence: 0.8,
      mergedFields: {},
    );
  }
}

/// Event representing a detected conflict between local and remote versions.
class ConflictEvent {
  /// The ID of the document associated with the conflict.
  final String documentId;

  /// The analysis details of the conflict.
  final ConflictAnalysis conflict;

  /// The timestamp when the conflict was detected.
  final DateTime detectedAt;

  /// Creates a [ConflictEvent] instance.
  ConflictEvent({
    required this.documentId,
    required this.conflict,
    required this.detectedAt,
  });
}

/// Levels of conflict severity.
enum ConflictSeverity {
  /// No conflict detected.
  none,

  /// Low severity conflict that can typically be auto-merged.
  low, // Can auto-merge

  /// Medium severity conflict that may require human review.
  medium, // Need human review

  /// High severity conflict representing major disparate changes.
  high, // Major conflict
}

/// Event representing the resolution of a previously detected conflict.
class ResolutionEvent {
  /// The ID of the resolved document.
  final String documentId;

  /// The timestamp when the resolution was applied.
  final DateTime resolvedAt;

  /// A note describing the resolution.
  final String resolutionNote;

  /// Whether the resolution was successful.
  final bool success;

  /// Creates a [ResolutionEvent] instance.
  ResolutionEvent({
    required this.documentId,
    required this.resolvedAt,
    required this.resolutionNote,
    required this.success,
  });
}

/// Strategies for resolving conflicts.
enum ResolutionStrategy {
  /// The version with the latest timestamp wins.
  lastWriteWins,

  /// The version with the earliest timestamp wins.
  firstWriteWins,

  /// The version with the larger logical clock magnitude wins.
  largerVersionWins,

  /// Non-conflicting fields are merged from both versions.
  fieldLevelMerge,

  /// Automatic resolution is not possible; user intervention is required.
  requiresManualResolution,
}
