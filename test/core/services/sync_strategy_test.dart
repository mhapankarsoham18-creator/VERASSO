// ignore_for_file: must_be_immutable
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/core/services/sync_strategy_service.dart';

// --- TEST ---

void main() {
  late MockSupabaseClient mockSupabase;
  late MockNetworkConnectivityService mockNetwork;
  late MockBluetoothMeshService mockMesh;
  late MockOfflineStorageService mockStorage;
  late SyncStrategyService syncService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockNetwork = MockNetworkConnectivityService();
    mockMesh = MockBluetoothMeshService();
    mockStorage = MockOfflineStorageService();
    syncService =
        SyncStrategyService(mockNetwork, mockMesh, mockStorage, mockSupabase);
  });

  group('SyncStrategyService', () {
    test('determineSyncMode prioritizes Mesh if active', () async {
      when(mockMesh.isMeshActive).thenReturn(true);
      expect(await syncService.determineSyncMode(), SyncMode.mesh);
    });

    test('determineSyncMode returns Realtime if WiFi connected', () async {
      when(mockMesh.isMeshActive).thenReturn(false);
      when(mockNetwork.isConnected).thenAnswer((_) async => true);
      expect(await syncService.determineSyncMode(), SyncMode.realtime);
    });

    test('determineSyncMode returns Offline if no connection', () async {
      when(mockMesh.isMeshActive).thenReturn(false);
      when(mockNetwork.isConnected).thenAnswer((_) async => false);
      expect(await syncService.determineSyncMode(), SyncMode.offline);
    });

    test('syncPendingActions does nothing if offline', () async {
      when(mockMesh.isMeshActive).thenReturn(false);
      when(mockNetwork.isConnected).thenAnswer((_) async => false);

      await syncService.syncPendingActions();

      verifyNever(mockStorage.getPendingActionsMap());
    });

    test('syncPendingActions processes via Mesh if Mesh active', () async {
      // Arrange
      when(mockMesh.isMeshActive).thenReturn(true);
      when(mockNetwork.isConnected).thenAnswer((_) async => false);

      final pendingAction = {
        'type': 'create_project',
        'data': {'title': 'New Project'}
      };

      when(mockStorage.getPendingActionsMap())
          .thenReturn({'key1': pendingAction});

      // Act
      await syncService.syncPendingActions();

      // Assert
      // Should broadcast to mesh
      verify(mockMesh.broadcastPacket(
        MeshPayloadType.feedPost,
        any,
        targetSubject: anyNamed('targetSubject'),
        priority: anyNamed('priority'),
      )).called(1);
      // Should NOT delete action (logic says keep it for cloud sync)
      verifyNever(mockStorage.deleteAction('key1'));
    });

    test('syncPendingActions processes via Realtime (Supabase) if Online',
        () async {
      // Arrange
      when(mockMesh.isMeshActive).thenReturn(false);
      when(mockNetwork.isConnected).thenAnswer((_) async => true);

      final pendingAction = {
        'type': 'create_project',
        'data': {
          'title': 'New Project',
          'temp_id': 'tmp1',
          'leader_id': 'user1'
        }
      };
      when(mockStorage.getPendingActionsMap())
          .thenReturn({'key1': pendingAction});

      // Mock Supabase interactions
      final mockBuilder =
          MockSupabaseQueryBuilder(insertResponse: {'id': 'real_id_1'});
      mockSupabase.setQueryBuilder('projects', mockBuilder);
      mockSupabase.setQueryBuilder(
          'project_members', MockSupabaseQueryBuilder());

      // Act
      await syncService.syncPendingActions();

      // Assert
      // Should insert to Supabase
      verify(mockSupabase.from('projects')).called(1);
      // Verify insert was called on the builder

      // Should delete action after successful sync
      verify(mockStorage.deleteAction('key1')).called(1);
    });
  });
}

// --- MOCKS ---

class MockBluetoothMeshService extends Mock implements BluetoothMeshService {
  @override
  bool get isMeshActive => super.noSuchMethod(
        Invocation.getter(#isMeshActive),
        returnValue: false,
      );

  @override
  Future<void> broadcastPacket(
          MeshPayloadType type, Map<String, dynamic>? payload,
          {String? targetSubject, MeshPriority? priority}) async =>
      super.noSuchMethod(
        Invocation.method(#broadcastPacket, [
          type,
          payload
        ], {
          #targetSubject: targetSubject,
          #priority: priority,
        }),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );
}

class MockGoTrueClient extends Mock implements GoTrueClient {
  @override
  User? get currentUser => User(
      id: 'test-user',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '');
}

class MockNetworkConnectivityService extends Mock
    implements NetworkConnectivityService {
  @override
  Future<bool> get isConnected => super.noSuchMethod(
        Invocation.getter(#isConnected),
        returnValue: Future.value(false),
      );
}

class MockOfflineStorageService extends Mock implements OfflineStorageService {
  @override
  Future<void> deleteAction(dynamic key) async => super.noSuchMethod(
        Invocation.method(#deleteAction, [key]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      );

  @override
  Map<dynamic, dynamic> getPendingActionsMap() => super.noSuchMethod(
        Invocation.method(#getPendingActionsMap, []),
        returnValue: <dynamic, dynamic>{},
      );
}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  final T _response;
  MockPostgrestFilterBuilder(this._response);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    Map<String, dynamic>? mapData;
    if (_response is List && (_response as List).isNotEmpty) {
      mapData = (_response as List).first as Map<String, dynamic>;
    } else if (_response is Map) {
      mapData = _response as Map<String, dynamic>;
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>?>(mapData);
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    List<Map<String, dynamic>> listData = [];
    if (_response is List) {
      listData = (_response as List).cast<Map<String, dynamic>>();
    } else if (_response is Map) {
      listData = [_response as Map<String, dynamic>];
    }
    return MockPostgrestTransformBuilder<List<Map<String, dynamic>>>(listData);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    Map<String, dynamic> mapData = {};
    if (_response is List && (_response as List).isNotEmpty) {
      mapData = (_response as List).first as Map<String, dynamic>;
    } else if (_response is Map) {
      mapData = _response as Map<String, dynamic>;
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>>(mapData);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(_response).then(onValue, onError: onError);
  }
}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  final T _response;
  MockPostgrestTransformBuilder(this._response);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    Map<String, dynamic>? mapData;
    if (_response is List && (_response as List).isNotEmpty) {
      mapData = (_response as List).first as Map<String, dynamic>;
    } else if (_response is Map) {
      mapData = _response as Map<String, dynamic>;
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>?>(mapData);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    Map<String, dynamic> mapData = {};
    if (_response is List && (_response as List).isNotEmpty) {
      mapData = (_response as List).first as Map<String, dynamic>;
    } else if (_response is Map) {
      mapData = _response as Map<String, dynamic>;
    }
    return MockPostgrestTransformBuilder<Map<String, dynamic>>(mapData);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(_response).then(onValue, onError: onError);
  }
}

class MockSupabaseClient extends Mock implements SupabaseClient {
  final GoTrueClient _auth;
  final Map<String, SupabaseQueryBuilder> _overrides = {};

  MockSupabaseClient({GoTrueClient? auth}) : _auth = auth ?? MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    // Record the interaction!
    super.noSuchMethod(Invocation.method(#from, [table]));
    return _overrides[table] ?? MockSupabaseQueryBuilder();
  }

  void setQueryBuilder(String table, SupabaseQueryBuilder builder) {
    _overrides[table] = builder;
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> _selectResponse;
  final Map<String, dynamic>? _insertResponse;

  MockSupabaseQueryBuilder({
    List<Map<String, dynamic>>? selectResponse,
    Map<String, dynamic>? insertResponse,
  })  : _selectResponse = selectResponse ?? [],
        _insertResponse = insertResponse;

  @override
  PostgrestFilterBuilder insert(Object values, {bool defaultToNull = false}) {
    // Record interaction
    super.noSuchMethod(
        Invocation.method(#insert, [values], {#defaultToNull: defaultToNull}));

    if (_insertResponse != null) {
      return MockPostgrestFilterBuilder([_insertResponse]);
    }
    return MockPostgrestFilterBuilder([]);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    return MockPostgrestFilterBuilder(_selectResponse);
  }

  @override
  PostgrestFilterBuilder update(Map values) {
    return MockPostgrestFilterBuilder([]);
  }
}
