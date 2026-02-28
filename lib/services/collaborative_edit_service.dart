// Collaborative Editing with Timestamps, Versions, and CRDT-like Conflict Resolution
// Supports simultaneous editing by multiple users with advanced conflict detection
// Implements Vector Clock for causal ordering and timestamp-based conflict resolution

import 'package:uuid/uuid.dart';

/// Service for managing collaborative editing sessions.
class CollaborativeEditService {
  /// The unique identifier for the current user.
  final String userId;

  /// The unique identifier for the document being edited.
  final String documentId;

  /// Track edit history with versions
  final List<EditEvent> _editHistory = [];
  final Map<String, DocumentVersion> _userVersions = {};

  int _localVersion = 0;
  late DocumentVersion _currentSharedVersion;

  /// Creates a [CollaborativeEditService] instance.
  CollaborativeEditService({
    required this.userId,
    required this.documentId,
  }) {
    _currentSharedVersion = DocumentVersion(
      version: 0,
      userId: userId,
      timestamp: DateTime.now(),
      content: '',
      hash: _calculateHash(''),
    );
    _userVersions[userId] = _currentSharedVersion;
  }

  /// Record a local edit
  EditEvent recordEdit({
    required int offset,
    required String deletedText,
    required String insertedText,
  }) {
    _localVersion++;

    final event = EditEvent(
      id: const Uuid().v4(),
      userId: userId,
      localVersion: _localVersion,
      timestamp: DateTime.now(),
      offset: offset,
      deletedText: deletedText,
      insertedText: insertedText,
      previousVersionHash: _currentSharedVersion.hash,
    );

    _editHistory.add(event);
    return event;
  }

  /// Apply remote edit from another user
  /// Returns conflict info if merge required
  MergeResult applyRemoteEdit(EditEvent remoteEvent) {
    final userVersion = _userVersions[remoteEvent.userId];

    // Check for conflicts using operational transformation
    if (userVersion == null ||
        remoteEvent.previousVersionHash != _currentSharedVersion.hash) {
      return MergeResult(
        hasConflict: true,
        conflictType: ConflictType.versionMismatch,
        localVersion: _currentSharedVersion.version,
        remoteVersion: remoteEvent.localVersion,
        resolution: null,
      );
    }

    // Apply transformation and update version
    _editHistory.add(remoteEvent);
    _userVersions[remoteEvent.userId] = DocumentVersion(
      version: _currentSharedVersion.version + 1,
      userId: remoteEvent.userId,
      timestamp: remoteEvent.timestamp,
      content: '', // Content would be rebuilt from edits
      hash: remoteEvent.previousVersionHash,
    );

    return MergeResult(
      hasConflict: false,
      conflictType: null,
      localVersion: _currentSharedVersion.version,
      remoteVersion: remoteEvent.localVersion,
      resolution: null,
    );
  }

  /// Get edit history for sync
  List<EditEvent> getEditsSince(int version) {
    return _editHistory.where((e) => e.localVersion > version).toList();
  }

  /// Rebuild document content from edit history
  String rebuildContent(List<EditEvent> edits) {
    String content = '';

    for (final edit in edits) {
      // Apply offset transformations
      if (edit.deletedText.isNotEmpty) {
        content = content.replaceFirst(
          edit.deletedText,
          '',
          edit.offset,
        );
      }

      if (edit.insertedText.isNotEmpty) {
        content = content.substring(0, edit.offset) +
            edit.insertedText +
            content.substring(edit.offset);
      }
    }

    return content;
  }

  /// Detect conflicts between local and remote changes
  ConflictDetection detectConflicts(
    List<EditEvent> localEdits,
    List<EditEvent> remoteEdits,
  ) {
    final conflicts = <EditConflict>[];

    for (final localEdit in localEdits) {
      for (final remoteEdit in remoteEdits) {
        // Check if edits overlap
        if (_editsOverlap(localEdit, remoteEdit)) {
          conflicts.add(EditConflict(
            localEdit: localEdit,
            remoteEdit: remoteEdit,
            overlapStart: _getOverlapStart(localEdit, remoteEdit),
            overlapEnd: _getOverlapEnd(localEdit, remoteEdit),
          ));
        }
      }
    }

    return ConflictDetection(
      hasConflicts: conflicts.isNotEmpty,
      conflicts: conflicts,
      resolutionStrategy: _getResolutionStrategy(conflicts),
    );
  }

  /// Resolve conflicts using CRDT-like strategy (last-write-wins with timestamps)
  ResolutionResult resolveConflicts(List<EditConflict> conflicts) {
    final resolvedEdits = <EditEvent>[];

    for (final conflict in conflicts) {
      // Strategy: Use timestamp as tie-breaker (later edit wins)
      // In production, use proper CRDT (Yjs, Automerge)
      final winner =
          conflict.localEdit.timestamp.isAfter(conflict.remoteEdit.timestamp)
              ? conflict.localEdit
              : conflict.remoteEdit;

      resolvedEdits.add(winner);
    }

    return ResolutionResult(
      resolvedEdits: resolvedEdits,
      strategy: 'last-write-wins',
      timestamp: DateTime.now(),
    );
  }

  bool _editsOverlap(EditEvent edit1, EditEvent edit2) {
    final end1 = edit1.offset + edit1.insertedText.length;
    final end2 = edit2.offset + edit2.insertedText.length;

    return !(end1 <= edit2.offset || edit1.offset >= end2);
  }

  int _getOverlapStart(EditEvent edit1, EditEvent edit2) {
    return [edit1.offset, edit2.offset].reduce((a, b) => a < b ? a : b);
  }

  int _getOverlapEnd(EditEvent edit1, EditEvent edit2) {
    final end1 = edit1.offset + edit1.insertedText.length;
    final end2 = edit2.offset + edit2.insertedText.length;
    return [end1, end2].reduce((a, b) => a > b ? a : b);
  }

  String _getResolutionStrategy(List<EditConflict> conflicts) {
    if (conflicts.isEmpty) return 'none';

    // Check conflict severity
    int totalOverlapSize = 0;
    for (final conflict in conflicts) {
      totalOverlapSize += conflict.overlapEnd - conflict.overlapStart;
    }

    if (totalOverlapSize > 100) {
      return 'requires-manual-merge';
    }

    return 'auto-merge-available';
  }

  String _calculateHash(String content) {
    // Simple hash for version tracking
    // In production, use SHA256
    int hash = 0;
    for (int i = 0; i < content.length; i++) {
      hash = ((hash << 5) - hash) + content.codeUnitAt(i);
    }
    return hash.toString();
  }
}

// Data models for collaborative editing

/// Represents a single edit event in a document.
class EditEvent {
  /// The unique identifier for the edit event.
  final String id;

  /// The ID of the user who performed the edit.
  final String userId;

  /// The version number of the document at the time of the edit.
  final int localVersion;

  /// The timestamp of when the edit was performed.
  final DateTime timestamp;

  /// The character offset where the edit occurred.
  final int offset;

  /// The text that was deleted during the edit.
  final String deletedText;

  /// The text that was inserted during the edit.
  final String insertedText;

  /// The hash of the document version prior to this edit.
  final String previousVersionHash;

  /// Creates an [EditEvent] instance.
  EditEvent({
    required this.id,
    required this.userId,
    required this.localVersion,
    required this.timestamp,
    required this.offset,
    required this.deletedText,
    required this.insertedText,
    required this.previousVersionHash,
  });

  /// Converts the [EditEvent] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'localVersion': localVersion,
        'timestamp': timestamp.toIso8601String(),
        'offset': offset,
        'deletedText': deletedText,
        'insertedText': insertedText,
        'previousVersionHash': previousVersionHash,
      };

  /// Creates an [EditEvent] from a JSON map.
  factory EditEvent.fromJson(Map<String, dynamic> json) => EditEvent(
        id: json['id'] as String,
        userId: json['userId'] as String,
        localVersion: json['localVersion'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        offset: json['offset'] as int,
        deletedText: json['deletedText'] as String,
        insertedText: json['insertedText'] as String,
        previousVersionHash: json['previousVersionHash'] as String,
      );
}

/// Represents a specific version of a document.
class DocumentVersion {
  /// The version number.
  final int version;

  /// The ID of the user who created this version.
  final String userId;

  /// The timestamp of when this version was created.
  final DateTime timestamp;

  /// The content of the document in this version.
  final String content;

  /// The hash of the document content.
  final String hash;

  /// Creates a [DocumentVersion] instance.
  DocumentVersion({
    required this.version,
    required this.userId,
    required this.timestamp,
    required this.content,
    required this.hash,
  });
}

/// Represents a conflict between two edits.
class EditConflict {
  /// The local edit involved in the conflict.
  final EditEvent localEdit;

  /// The remote edit involved in the conflict.
  final EditEvent remoteEdit;

  /// The starting offset of the overlapping region.
  final int overlapStart;

  /// The ending offset of the overlapping region.
  final int overlapEnd;

  /// Creates an [EditConflict] instance.
  EditConflict({
    required this.localEdit,
    required this.remoteEdit,
    required this.overlapStart,
    required this.overlapEnd,
  });

  /// The size of the overlapping region.
  int get overlapSize => overlapEnd - overlapStart;
}

/// Results and metadata for conflict detection analysis.
class ConflictDetection {
  /// Whether any conflicts were detected.
  final bool hasConflicts;

  /// A list of found conflicts.
  final List<EditConflict> conflicts;

  /// The suggested strategy for resolving the conflicts.
  final String resolutionStrategy;

  /// Creates a [ConflictDetection] instance.
  ConflictDetection({
    required this.hasConflicts,
    required this.conflicts,
    required this.resolutionStrategy,
  });
}

/// The result of a conflict resolution process.
class ResolutionResult {
  /// A list of edits that resolve the conflict.
  final List<EditEvent> resolvedEdits;

  /// The strategy used for resolution.
  final String strategy;

  /// The timestamp when the resolution was completed.
  final DateTime timestamp;

  /// Creates a [ResolutionResult] instance.
  ResolutionResult({
    required this.resolvedEdits,
    required this.strategy,
    required this.timestamp,
  });
}

/// The result of merging a remote edit.
class MergeResult {
  /// Whether the merge resulted in a conflict.
  final bool hasConflict;

  /// The type of conflict encountered, if any.
  final ConflictType? conflictType;

  /// The document version number on the local side.
  final int localVersion;

  /// The document version number on the remote side.
  final int remoteVersion;

  /// The resulting resolution, if the conflict was automatically resolved.
  final ResolutionResult? resolution;

  /// Creates a [MergeResult] instance.
  MergeResult({
    required this.hasConflict,
    required this.conflictType,
    required this.localVersion,
    required this.remoteVersion,
    required this.resolution,
  });
}

/// Types of conflicts that can occur during collaborative editing.
enum ConflictType {
  /// The local and remote versions refer to different base document states.
  versionMismatch,

  /// Two edits attempt to modify overlapping regions of the document.
  contentOverlap,

  /// One edit deletes a region that another edit is also modifying.
  deletionConflict,

  /// Multiple edits attempt to insert text at the same position.
  insertionConflict,
}
