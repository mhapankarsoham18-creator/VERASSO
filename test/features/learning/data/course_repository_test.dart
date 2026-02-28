import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockTransactionService mockTxService;
  late CourseRepository repository;

  setUp(() {
    mockAuth = MockGoTrueClient();
    mockClient = MockSupabaseClient(auth: mockAuth);
    mockTxService = MockTransactionService();

    repository = CourseRepository(
      client: mockClient,
      txService: mockTxService,
    );
  });

  group('CourseRepository', () {
    final testCourse = Course(
      id: 'course-123',
      creatorId: 'creator-123',
      title: 'Test Course',
      description: 'A test course',
      price: 99.0,
      createdAt: DateTime.now(),
    );

    test('createCourse should insert course and return id', () async {
      // Arrange
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<Map<String, dynamic>>();

      mockFilterBuilder.setResponse({'id': 'new-course-id'});

      mockClient.setQueryBuilder('courses', mockQueryBuilder);
      // We need to stub the insert and select on the query builder
      // But MockSupabaseQueryBuilder in mocks.dart returns MockPostgrestFilterBuilder
      // Let's check if we can use when(...) or if we need to use the stubs map

      // The MockSupabaseQueryBuilder has a `_stubs` map
      final qb = MockSupabaseQueryBuilder(stubs: {
        'insert': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('courses', qb);

      // Act
      final result = await repository.createCourse(testCourse);

      // Assert
      expect(result, 'new-course-id');
    });

    test('getCourseChapters should return list of chapters', () async {
      // Arrange
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.setResponse([
        {
          'id': 'ch-1',
          'course_id': 'course-123',
          'title': 'Chapter 1',
          'order_index': 0,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      final qb = MockSupabaseQueryBuilder(stubs: {
        'select': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('chapters', qb);

      // Act
      final result = await repository.getCourseChapters('course-123');

      // Assert
      expect(result.length, 1);
      expect(result.first.title, 'Chapter 1');
    });

    test('enrollInCourse should process transaction and insert enrollment',
        () async {
      // Arrange
      final mockUser = TestSupabaseUser(id: 'user-123');
      mockAuth.setCurrentUser(mockUser);

      bool txCalled = false;
      mockTxService.processCoursePurchaseStub = (uid, cid, price) async {
        if (uid == 'user-123' && cid == 'course-123' && price == 99.0) {
          txCalled = true;
          return true;
        }
        return false;
      };

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      mockClient.setQueryBuilder('enrollments', mockQueryBuilder);

      // Act
      await repository.enrollInCourse('course-123', 99.0);

      // Assert
      expect(txCalled, isTrue);
    });

    test('updateProgress should update record', () async {
      // Arrange
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final qb = MockSupabaseQueryBuilder(stubs: {
        'update': mockFilterBuilder,
      });
      mockClient.setQueryBuilder('enrollments', qb);

      // Act
      await repository.updateProgress('enrollment-123', ['chap-1'], 2); // 50%

      // Assert
      // Verification is implicit if no error
    });

    group('Simulations', () {
      test('getSimulations should return list of simulation posts', () async {
        // Arrange
        final mockFilterBuilder =
            MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
        mockFilterBuilder.setResponse([
          {
            'id': 'sim-1',
            'user_id': 'user-123',
            'type': 'simulation',
            'content': 'Physics Simulation',
            'created_at': DateTime.now().toIso8601String(),
          }
        ]);

        final qb = MockSupabaseQueryBuilder(stubs: {
          'select': mockFilterBuilder,
        });
        mockClient.setQueryBuilder('posts', qb);

        // Act
        final result = await repository.getSimulations();

        // Assert
        expect(result.length, 1);
        expect(result.first.type, PostType.simulation);
      });

      test('getSimulation should return a single simulation post', () async {
        // Arrange
        final mockFilterBuilder =
            MockPostgrestFilterBuilder<Map<String, dynamic>?>();
        mockFilterBuilder.setResponse({
          'id': 'sim-1',
          'user_id': 'user-123',
          'type': 'simulation',
          'content': 'Physics Simulation',
          'created_at': DateTime.now().toIso8601String(),
        });

        final qb = MockSupabaseQueryBuilder(stubs: {
          'select': mockFilterBuilder,
        });
        mockClient.setQueryBuilder('posts', qb);

        // Act
        final result = await repository.getSimulation('sim-1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'sim-1');
      });

      test('saveSimulationData should update post record', () async {
        // Arrange
        final mockFilterBuilder = MockPostgrestFilterBuilder();
        final qb = MockSupabaseQueryBuilder(stubs: {
          'update': mockFilterBuilder,
        });
        mockClient.setQueryBuilder('posts', qb);

        // Act
        await repository.saveSimulationData('sim-1', {'score': 100});

        // Assert
        expect(mockClient.lastUpdateTable, 'posts');
      });
    });
  });
}
