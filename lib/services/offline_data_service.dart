// Offline-First Data Persistence with IndexDB Sync
// Saves changes locally when offline, syncs when connectivity returns

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service for managing offline-first data persistence and synchronization.
class OfflineDataService {
  static const String _dbName = 'verasso_offline.db';
  static const int _dbVersion = 1;
  Database? _database;
  final Connectivity _connectivity = Connectivity();

  /// Gets the underlying SQLite database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Caches data locally for offline access or performance.
  Future<void> cacheData({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    int? ttlSeconds,
  }) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = ttlSeconds != null
        ? timestamp + (ttlSeconds * 1000)
        : null;

    await db.insert(
      'local_cache',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'data': jsonEncode(data),
        'version': 1,
        'last_sync_at': timestamp,
        'expires_at': expiresAt,
        'created_at': timestamp,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Checks the current network connectivity status.
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && 
           result.first != ConnectivityResult.none;
  }

  /// Clears any cache entries that have passed their expiration time.
  Future<int> clearExpiredCache() async {
    final db = await database;
    return db.delete(
      'local_cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Closes the local database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Retrieves cached data for a specific entity.
  Future<Map<String, dynamic>?> getCachedData(
    String entityType,
    String entityId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'local_cache',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    
    // Check if expired
    if (row['expires_at'] != null) {
      if (row['expires_at'] as int < DateTime.now().millisecondsSinceEpoch) {
        await db.delete(
          'local_cache',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        return null;
      }
    }

    return jsonDecode(row['data'] as String) as Map<String, dynamic>;
  }

  /// Retrieves a list of all changes that are pending synchronization.
  Future<List<PendingChange>> getPendingChanges() async {
    final db = await database;
    final rows = await db.query(
      'pending_changes',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return rows.map((row) => PendingChange.fromMap(row)).toList();
  }

  /// Checks if the device is currently online.
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  /// Marks a specific pending change as successfully synchronized.
  Future<void> markAssynced(int changeId) async {
    final db = await database;
    await db.update(
      'pending_changes',
      {
        'synced': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [changeId],
    );
  }

  /// Returns a stream of connectivity status changes.
  Stream<List<ConnectivityResult>> monitorConnectivity() {
    return _connectivity.onConnectivityChanged;
  }

  /// Records an error that occurred during a synchronization attempt.
  Future<void> recordSyncError(int changeId, String errorMessage) async {
    final db = await database;
    // Get current attempt count first
    final result = await db.query(
      'pending_changes',
      columns: ['sync_attempts'],
      where: 'id = ?',
      whereArgs: [changeId],
    );
    int newAttempts = 1;
    if (result.isNotEmpty) {
      newAttempts = (result.first['sync_attempts'] as int? ?? 0) + 1;
    }
    
    await db.update(
      'pending_changes',
      {
        'error_message': errorMessage,
        'sync_attempts': newAttempts,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [changeId],
    );
  }

  /// Saves a change locally to be synchronized later.
  Future<int> savePendingChange({
    required String entityType,
    required String entityId,
    required String operation, // 'CREATE', 'UPDATE', 'DELETE'
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return db.insert(
      'pending_changes',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'data': jsonEncode(data),
        'timestamp': timestamp,
        'synced': 0,
        'sync_attempts': 0,
        'created_at': timestamp,
        'updated_at': timestamp,
      },
    );
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
    // Pending changes table
    await db.execute('''
      CREATE TABLE pending_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced BOOLEAN DEFAULT 0,
        sync_attempts INTEGER DEFAULT 0,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Local cache table
    await db.execute('''
      CREATE TABLE local_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        data TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        last_sync_at INTEGER,
        expires_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Sync metadata
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_successful_sync INTEGER,
        last_attempted_sync INTEGER,
        sync_status TEXT,
        pending_count INTEGER DEFAULT 0
      )
    ''');

    // Create indices
    await db.execute('''
      CREATE INDEX idx_pending_changes_synced 
      ON pending_changes(synced)
    ''');
    await db.execute('''
      CREATE INDEX idx_pending_changes_entity 
      ON pending_changes(entity_type, entity_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_local_cache_entity 
      ON local_cache(entity_type, entity_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations here
  }
}

/// Represents a change that is pending synchronization to the backend.
class PendingChange {
  /// The unique identifier for the pending change.
  final int id;

  /// The type of entity being changed (e.g., 'profile', 'document').
  final String entityType;

  /// The identifier of the entity being changed.
  final String entityId;

  /// The operation being performed (e.g., 'CREATE', 'UPDATE', 'DELETE').
  final String operation;

  /// The data associated with the change.
  final Map<String, dynamic> data;

  /// The timestamp of when the change occurred.
  final int timestamp;

  /// Whether the change has been synchronized.
  final bool synced;

  /// The number of sync attempts made for this change.
  final int syncAttempts;

  /// The error message if the last sync attempt failed.
  final String? errorMessage;

  /// Creates a [PendingChange] instance.
  PendingChange({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestamp,
    required this.synced,
    required this.syncAttempts,
    this.errorMessage,
  });

  /// Creates a [PendingChange] instance from a database map.
  factory PendingChange.fromMap(Map<String, dynamic> map) => PendingChange(
    id: map['id'] as int,
    entityType: map['entity_type'] as String,
    entityId: map['entity_id'] as String,
    operation: map['operation'] as String,
    data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
    timestamp: map['timestamp'] as int,
    synced: (map['synced'] as int) == 1,
    syncAttempts: map['sync_attempts'] as int,
    errorMessage: map['error_message'] as String?,
  );
}
