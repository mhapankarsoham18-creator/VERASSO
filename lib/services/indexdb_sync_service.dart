// IndexDB Storage Layer with Sync Bridge
// Handles client-side data persistence, versioning, and sync coordination

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// IndexDB Sync Service - Manages local data persistence and sync
/// A service that manages local data persistence using IndexDB (via sqflite) 
/// and coordinates synchronization with a remote backend.
class IndexDbSyncService {
  static const String _dbName = 'verasso_indexdb.db';
  static const int _dbVersion = 2;

  Database? _database;
  // final Connectivity _connectivity = Connectivity();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _conflictController = StreamController<SyncConflict>.broadcast();

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  /// A stream of synchronization conflicts discovered during sync attempts.
  Stream<SyncConflict> get conflictStream => _conflictController.stream;

  /// Gets the local database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// A stream of synchronization status updates.
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Clears completed synchronization operations that are older than the specified number of days.
  Future<int> clearCompletedOperations({int olderThanDays = 7}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .millisecondsSinceEpoch;

    return db.delete(
      'sync_queue',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['completed', cutoffTime],
    );
  }

  /// Closes the database connection and cancels active subscriptions.
  Future<void> close() async {
    await _connectivitySubscription.cancel();
    await _syncStatusController.close();
    await _conflictController.close();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Analyzes local and remote versions to detect potential synchronization conflicts.
  Future<SyncConflict?> detectConflict({
    required String documentId,
    required VectorClock localVersion,
    required VectorClock remoteVersion,
  }) async {
    // final db = await database;

    // Check if versions are concurrent (neither is ancestor of other)
    if (localVersion.happensBefore(remoteVersion) ||
        remoteVersion.happensBefore(localVersion)) {
      return null; // No conflict - one is ancestor of other
    }

    // Get both versions' content
    final localDoc = await getDocument(documentId);
    if (localDoc == null) return null;

    return SyncConflict(
      documentId: documentId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localContent: localDoc.content,
      timestamp: DateTime.now(),
    );
  }

  /// Emit a conflict event to listeners
  void emitConflict(SyncConflict conflict) {
    if (!_conflictController.isClosed) {
      _conflictController.add(conflict);
    }
  }

  /// Retrieves a document from the local storage by its identifier.
  Future<StoredDocument?> getDocument(String documentId) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [documentId],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return StoredDocument(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      documentType: row['document_type'] as String,
      content: jsonDecode(row['content'] as String) as Map<String, dynamic>,
      vectorClock: VectorClock.fromMap(
          jsonDecode(row['version_vector'] as String) as Map<String, dynamic>),
      timestamp: row['timestamp'] as int,
      isDeleted: (row['is_deleted'] as int) == 1,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
    );
  }

  /// Retrieves all synchronization operations that are currently in a 'pending' state.
  Future<List<SyncOperation>> getPendingSyncOperations() async {
    final db = await database;
    final rows = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    return rows
        .map((row) => SyncOperation(
              id: row['id'] as int,
              documentId: row['document_id'] as String,
              operation: row['operation'] as String,
              payload:
                  jsonDecode(row['payload'] as String) as Map<String, dynamic>,
              status: row['status'] as String,
              retryCount: row['retry_count'] as int,
              lastError: row['last_error'] as String?,
              createdAt: row['created_at'] as int,
              updatedAt: row['updated_at'] as int,
            ))
        .toList();
  }

  /// Retrieves the current synchronization status for a specific document.
  Future<SyncStatus?> getSyncStatus(String documentId) async {
    final db = await database;
    final rows = await db.query(
      'sync_metadata',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return SyncStatus(
      documentId: documentId,
      lastSyncedVersion: row['last_synced_version'] as int?,
      lastSyncedAt: row['last_synced_at'] as int?,
      isSynced: (row['is_synced'] as int) == 1,
      status: row['sync_status'] as String,
      pendingOperationsCount: row['pending_operations_count'] as int,
    );
  }

  /// Retrieves a list of all documents that have not yet been synchronized with the backend.
  Future<List<StoredDocument>> getUnsyncedDocuments() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT d.* FROM documents d
      JOIN sync_metadata sm ON d.id = sm.document_id
      WHERE sm.is_synced = 0
      ORDER BY d.updated_at ASC
    ''');

    return rows
        .map((row) => StoredDocument(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              documentType: row['document_type'] as String,
              content:
                  jsonDecode(row['content'] as String) as Map<String, dynamic>,
              vectorClock: VectorClock.fromMap(
                  jsonDecode(row['version_vector'] as String)
                      as Map<String, dynamic>),
              timestamp: row['timestamp'] as int,
              isDeleted: (row['is_deleted'] as int) == 1,
              createdAt: row['created_at'] as int,
              updatedAt: row['updated_at'] as int,
            ))
        .toList();
  }

  /// Marks a specific document as having been successfully synchronized.
  Future<void> markDocumentSynced(String documentId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'sync_metadata',
      {
        'is_synced': 1,
        'sync_status': 'completed',
        'last_synced_at': now,
        'pending_operations_count': 0,
      },
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }

  /// Marks a specific synchronization operation in the queue as 'completed'.
  Future<void> markSyncOperationComplete(int operationId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'sync_queue',
      {
        'status': 'completed',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Marks a specific synchronization operation in the queue as 'failed' and records the error.
  Future<void> markSyncOperationFailed(
    int operationId,
    String errorMessage,
  ) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get current retry count
    final result = await db.query(
      'sync_queue',
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [operationId],
    );

    final currentRetryCount =
        result.isNotEmpty ? (result.first['retry_count'] as int? ?? 0) : 0;

    await db.update(
      'sync_queue',
      {
        'status': 'failed',
        'last_error': errorMessage,
        'retry_count': currentRetryCount + 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Adds a new synchronization operation (CREATE, UPDATE, DELETE) to the local queue.
  Future<int> queueSyncOperation({
    required String documentId,
    required String operation, // 'CREATE', 'UPDATE', 'DELETE'
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return db.insert(
      'sync_queue',
      {
        'document_id': documentId,
        'operation': operation,
        'payload': jsonEncode(payload),
        'status': 'pending',
        'retry_count': 0,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  /// Records a document change in the local log for version tracking and audits.
  Future<void> recordChange({
    required String documentId,
    required String userId,
    required String operation,
    required VectorClock vectorClock,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'change_log',
      {
        'document_id': documentId,
        'user_id': userId,
        'operation': operation,
        'timestamp': now,
        'vector_clock': jsonEncode(vectorClock.toMap()),
        'created_at': now,
      },
    );
  }

  /// Stores a document record in the local database with versioning and sync metadata.
  Future<void> storeDocument({
    required String documentId,
    required String userId,
    required String documentType,
    required Map<String, dynamic> content,
    required VectorClock vectorClock,
    bool isDeleted = false,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Store document
      await txn.insert(
        'documents',
        {
          'id': documentId,
          'user_id': userId,
          'document_type': documentType,
          'content': jsonEncode(content),
          'version_vector': jsonEncode(vectorClock.toMap()),
          'timestamp': now,
          'is_deleted': isDeleted ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Store version in document_versions
      final currentVersion = await txn.query(
        'document_versions',
        where: 'document_id = ?',
        whereArgs: [documentId],
        orderBy: 'version DESC',
        limit: 1,
      );

      final nextVersion = (currentVersion.isEmpty
              ? 0
              : currentVersion.first['version'] as int) +
          1;

      await txn.insert(
        'document_versions',
        {
          'document_id': documentId,
          'version': nextVersion,
          'user_id': userId,
          'content_hash': _hashContent(content),
          'vector_clock': jsonEncode(vectorClock.toMap()),
          'timestamp': now,
          'created_at': now,
        },
      );

      // Update sync metadata
      await txn.insert(
        'sync_metadata',
        {
          'document_id': documentId,
          'last_synced_version': nextVersion,
          'is_synced': 0, // Mark as unsynced
          'sync_status': 'pending',
          'pending_operations_count': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  String _hashContent(Map<String, dynamic> content) {
    return content.toString().hashCode.toString();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Document storage table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        document_type TEXT NOT NULL,
        content TEXT NOT NULL,
        version_vector TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_deleted BOOLEAN DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Document versions table (for conflict detection)
    await db.execute('''
      CREATE TABLE document_versions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        content_hash TEXT NOT NULL,
        vector_clock TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(document_id, version),
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Sync metadata table
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT NOT NULL UNIQUE,
        last_synced_version INTEGER,
        last_synced_at INTEGER,
        last_sync_attempt INTEGER,
        sync_status TEXT DEFAULT 'idle',
        pending_operations_count INTEGER DEFAULT 0,
        is_synced BOOLEAN DEFAULT 1,
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Change log for version vectors
    await db.execute('''
      CREATE TABLE change_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        vector_clock TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(document_id) REFERENCES documents(id)
      )
    ''');

    // Create indices
    await db.execute('CREATE INDEX idx_documents_user ON documents(user_id)');
    await db
        .execute('CREATE INDEX idx_documents_type ON documents(document_type)');
    await db
        .execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status)');
    await db.execute(
        'CREATE INDEX idx_sync_queue_document ON sync_queue(document_id)');
    await db.execute(
        'CREATE INDEX idx_change_log_document ON change_log(document_id)');
    await db.execute(
        'CREATE INDEX idx_document_versions_document ON document_versions(document_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add any missing tables or columns in version 2+
      await db.execute('''
        CREATE TABLE IF NOT EXISTS change_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          document_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          vector_clock TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY(document_id) REFERENCES documents(id)
        )
      ''');
    }
  }
}

/// Represents a stored document
/// Represents a document stored in the local database.
class StoredDocument {
  /// The unique identifier for the document.
  final String id;

  /// The ID of the user who owns or last modified the document.
  final String userId;

  /// The type of document (e.g., 'note', 'task').
  final String documentType;

  /// The actual content of the document as a JSON-compatible map.
  final Map<String, dynamic> content;

  /// The vector clock representing the document's version.
  final VectorClock vectorClock;

  /// The timestamp of the document's last modification.
  final int timestamp;

  /// Whether the document has been marked as deleted.
  final bool isDeleted;

  /// The timestamp when the document was first created locally.
  final int createdAt;

  /// The timestamp of the last local update to the document record.
  final int updatedAt;

  /// Creates a new [StoredDocument] instance.
  StoredDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.content,
    required this.vectorClock,
    required this.timestamp,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Represents a sync conflict
/// Represents a conflict between a local document version and a remote version.
class SyncConflict {
  /// The ID of the document with the conflict.
  final String documentId;

  /// The local version of the document (vector clock).
  final VectorClock localVersion;

  /// The remote version of the document (vector clock).
  final VectorClock remoteVersion;

  /// The local content of the document at the time of conflict discovery.
  final Map<String, dynamic> localContent;

  /// The timestamp when the conflict was detected.
  final DateTime timestamp;

  /// Creates a new [SyncConflict] instance.
  SyncConflict({
    required this.documentId,
    required this.localVersion,
    required this.remoteVersion,
    required this.localContent,
    required this.timestamp,
  });
}

/// Represents a pending sync operation
/// Represents an operation (CREATE, UPDATE, DELETE) queued for synchronization.
class SyncOperation {
  /// The unique identifier for the operation in the local queue.
  final int id;

  /// The ID of the document associated with the operation.
  final String documentId;

  /// The type of operation ('CREATE', 'UPDATE', or 'DELETE').
  final String operation;

  /// The payload data associated with the operation.
  final Map<String, dynamic> payload;

  /// The current status of the operation (e.g., 'pending', 'completed', 'failed').
  final String status;

  /// The number of times this operation has been retried.
  final int retryCount;

  /// The last error message encountered during a sync attempt, if any.
  final String? lastError;

  /// The timestamp when the operation was created.
  final int createdAt;

  /// The timestamp of the last status update for this operation.
  final int updatedAt;

  /// Creates a new [SyncOperation] instance.
  SyncOperation({
    required this.id,
    required this.documentId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Sync status information
/// Represents the synchronization status of a document.
class SyncStatus {
  /// The ID of the document.
  final String documentId;

  /// The last version number that was successfully synced.
  final int? lastSyncedVersion;

  /// The timestamp of the last successful synchronization.
  final int? lastSyncedAt;

  /// Whether the document is currently in sync with the remote backend.
  final bool isSynced;

  /// A descriptive string representing the current sync status.
  final String status;

  /// The number of operations still pending for this document.
  final int pendingOperationsCount;

  /// Creates a new [SyncStatus] instance.
  SyncStatus({
    required this.documentId,
    this.lastSyncedVersion,
    this.lastSyncedAt,
    required this.isSynced,
    required this.status,
    required this.pendingOperationsCount,
  });
}

/// Vector clock for version tracking
/// A vector clock used for tracking causality and versioning in a distributed system.
class VectorClock {
  /// The internal map of user IDs to their respective logical clock values.
  final Map<String, int> clock;

  /// Creates a new [VectorClock] instance, optionally with an initial state.
  VectorClock({Map<String, int>? clock}) : clock = clock ?? {};

  /// Creates a [VectorClock] from a map of user IDs to clock values.
  factory VectorClock.fromMap(Map<String, dynamic> map) {
    return VectorClock(
      clock: map.cast<String, int>(),
    );
  }

  /// Check if this clock happens before another
  bool happensBefore(VectorClock other) {
    bool hasSmallerComponent = false;
    for (final userId in {...clock.keys, ...other.clock.keys}) {
      final thisValue = clock[userId] ?? 0;
      final otherValue = other.clock[userId] ?? 0;

      if (thisValue > otherValue) return false;
      if (thisValue < otherValue) hasSmallerComponent = true;
    }
    return hasSmallerComponent;
  }

  /// Increment the clock for a given user
  void increment(String userId) {
    clock[userId] = (clock[userId] ?? 0) + 1;
  }

  /// Check if clocks are concurrent
  bool isConcurrent(VectorClock other) {
    return !happensBefore(other) && !other.happensBefore(this);
  }

  /// Calculate the magnitude (total increment count) of the vector clock
  int magnitude() {
    return clock.values.fold<int>(0, (sum, val) => sum + val);
  }

  /// Converts the [VectorClock] to a map for serialization.
  Map<String, int> toMap() => Map.from(clock);
}
