import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/features/talent/data/job_model.dart';
import 'package:verasso/features/talent/data/job_repository.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockNetworkConnectivityService mockNetwork;
  late MockOfflineStorageService mockStorage;
  late MockBluetoothMeshService mockMesh;
  late JobRepository repository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockNetwork = MockNetworkConnectivityService();
    mockStorage = MockOfflineStorageService();
    mockMesh = MockBluetoothMeshService();

    repository =
        JobRepository(mockSupabase, mockNetwork, mockStorage, mockMesh);
  });

  group('JobRepository Tests', () {
    group('applyForJob', () {
      test('should use mesh broadcast if mesh is active', () async {
        mockMesh.setIsMeshActive(true);
        mockNetwork.setIsConnected(false); // Ensure network doesn't interfere

        await repository.applyForJob('job-1', 'user-1', 'I am interested');

        // Verify storage queue action
        expect(mockStorage.queueActionRawCalls.length, 1);
        expect(mockStorage.queueActionRawCalls.first['actionType'],
            'apply_for_job');

        // Verify mesh broadcast
        expect(mockMesh.broadcastPacketCalls.length, 1);
        expect(mockMesh.broadcastPacketCalls.first['payload']['action'],
            'apply_for_job');
      });

      test('should use online insert if connected and mesh inactive', () async {
        mockMesh.setIsMeshActive(false);
        mockNetwork.setIsConnected(true);

        final builder = MockSupabaseQueryBuilder(selectResponse: []);
        mockSupabase.setQueryBuilder('job_applications', builder);

        await repository.applyForJob('job-1', 'user-1', 'I am interested');

        // Verify Supabase insert called
        expect(mockSupabase.from('job_applications'), isNotNull);
      });

      test('should queue action if offline and mesh inactive', () async {
        mockMesh.setIsMeshActive(false);
        mockNetwork.setIsConnected(false);

        await repository.applyForJob('job-1', 'user-1', 'I am interested');

        // Verify storage queue action
        expect(mockStorage.queueActionRawCalls.length, 1);
        expect(mockStorage.queueActionRawCalls.first['actionType'],
            'apply_for_job');

        // Verify NO mesh broadcast
        expect(mockMesh.broadcastPacketCalls.isEmpty, isTrue);
      });
    });

    group('createJobRequest', () {
      final jobRequest = JobRequest(
        id: 'job-1',
        clientId: 'client-1',
        title: 'Developer',
        description: 'Need help',
        budget: 100,
        currency: 'USD',
        requiredSkills: ['Dart'],
        status: 'open',
        createdAt: DateTime.now(),
      );

      test('should use mesh broadcast if mesh is active', () async {
        mockMesh.setIsMeshActive(true);

        await repository.createJobRequest(jobRequest);

        expect(mockStorage.queueActionRawCalls.length, 1);
        expect(mockMesh.broadcastPacketCalls.length, 1);
        expect(mockMesh.broadcastPacketCalls.first['type'],
            MeshPayloadType.feedPost);
      });

      test('should use online insert if connected', () async {
        mockMesh.setIsMeshActive(false);
        mockNetwork.setIsConnected(true);

        final builder = MockSupabaseQueryBuilder(selectResponse: []);
        mockSupabase.setQueryBuilder('job_requests', builder);

        await repository.createJobRequest(jobRequest);

        expect(mockSupabase.from('job_requests'), isNotNull);
      });
    });

    group('getJobRequests', () {
      test('should return cached data if offline', () async {
        mockNetwork.setIsConnected(false);

        // Stub cached data
        mockStorage.getCachedDataStub = (key, {expiration}) {
          if (key.startsWith('job_requests')) {
            return [
              {
                'id': 'job-cached',
                'client_id': 'c1',
                'title': 'Cached Job',
                'description': 'Desc',
                'budget': 50,
                'currency': 'USD',
                'skills': [],
                'status': 'open',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }
            ];
          }
          return null;
        };

        final jobs = await repository.getJobRequests();

        expect(jobs.length, 1);
        expect(jobs.first.title, 'Cached Job');
      });

      test('should fetch from network if online', () async {
        mockNetwork.setIsConnected(true);

        final response = [
          {
            'id': 'job-online',
            'client_id': 'c1',
            'title': 'Online Job',
            'description': 'Desc',
            'budget': 200,
            'currency': 'USD',
            'skills': [],
            'status': 'open',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'profiles': {'full_name': 'Client Name', 'avatar_url': null}
          }
        ];

        final builder = MockSupabaseQueryBuilder(selectResponse: response);
        mockSupabase.setQueryBuilder('job_requests', builder);

        final jobs = await repository.getJobRequests();

        expect(jobs.length, 1);
        expect(jobs.first.title, 'Online Job');
      });
    });
  });
}
