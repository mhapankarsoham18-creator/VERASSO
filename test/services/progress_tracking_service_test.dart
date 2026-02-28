import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

// Generate mocks
import '../mocks.dart';

void main() {
  late ProgressTrackingService service;
  late MockSupabaseClient mockSupabaseClient;
  setUp(() {
    mockSupabaseClient = MockSupabaseClient();

    service = ProgressTrackingService(client: mockSupabaseClient);
  });

  group('getUnlockedBadges', () {
    test('returns list of badge IDs when successful', () async {
      // Arrange
      final List<Map<String, dynamic>> mockData = [
        {'badge_id': 'badge_1'},
        {'badge_id': 'badge_2'},
      ];

      mockSupabaseClient.setQueryBuilder(
          'user_badges', MockSupabaseQueryBuilder(selectResponse: mockData));

      // Act
      final result = await service.getUnlockedBadges('test-user-id');

      // Assert
      expect(result, equals(['badge_1', 'badge_2']));
    });

    test('returns empty list on error', () async {
      // Arrange
      mockSupabaseClient.fromStub = (table) => throw Exception('DB Error');

      // Act
      final result = await service.getUnlockedBadges('test-user-id');

      // Assert
      expect(result, isEmpty);
    });
  });
}
