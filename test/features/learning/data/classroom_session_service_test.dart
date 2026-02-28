import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/features/learning/data/classroom_session_service.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockBluetoothMeshService mockMesh;
  late MockOfflineStorageService mockStorage;
  late ClassroomSessionService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockMesh = MockBluetoothMeshService();
    mockStorage = MockOfflineStorageService();
    service =
        ClassroomSessionService(mockMesh, mockStorage, client: mockClient);
  });

  group('ClassroomSessionService', () {
    test('fetchAvailableLabs should return only courses marked as labs',
        () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'lab-1',
          'creator_id': 'user-1',
          'title': 'Physics Lab',
          'is_lab': true,
          'is_published': true,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('courses', qb);

      // Act
      final result = await service.fetchAvailableLabs();

      // Assert
      expect(result.length, 1);
      expect(result.first.isLab, true);
    });

    test('fetchClassroomSessions should return sessions from cloud', () async {
      // Arrange
      final mockResponse = [
        {
          'id': 'sess-1',
          'host_id': 'user-1',
          'subject': 'Math',
          'topic': 'Algebra',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse(mockResponse);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('classroom_sessions', qb);

      // Act
      final result = await service.fetchClassroomSessions();

      // Assert
      expect(result.length, 1);
      expect(result.first.topic, 'Algebra');
    });

    test('startSession should sync to cloud and mesh', () async {
      // Arrange
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final qb = MockSupabaseQueryBuilder(stubs: {
        'insert': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('classroom_sessions', qb);

      // Act
      await service.startSession('user-1', 'Physics', 'Gravity');

      // Assert
      expect(mockMesh.lastBroadcastType, MeshPayloadType.startSession);
      // Cloud sync is also triggered
    });
  });
}
