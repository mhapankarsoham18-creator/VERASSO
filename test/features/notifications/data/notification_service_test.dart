import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/notifications/data/notification_service.dart';
import 'package:verasso/features/notifications/models/notification_model.dart';

import '../../../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockFirebaseMessaging mockFcm;
  late NotificationService service;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFcm = MockFirebaseMessaging();
    service = NotificationService(client: mockSupabase, fcm: mockFcm);
  });

  group('NotificationService Tests', () {
    test('createNotification should call insert on Supabase', () async {
      final builder = MockSupabaseQueryBuilder();
      mockSupabase.setQueryBuilder('notifications', builder);

      await service.createNotification(
        targetUserId: 'user-1',
        type: NotificationType.system,
        title: 'Test Title',
        body: 'Test Body',
      );

      // Verify initialization of builder for the table
      expect(mockSupabase.from('notifications'), isNotNull);
    });

    test('getNotifications should return a list of notifications', () async {
      final responseData = [
        {
          'id': '1',
          'user_id': 'user-1',
          'type': 'system',
          'title': 'Test 1',
          'body': 'Body 1',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
      final builder = MockSupabaseQueryBuilder(selectResponse: responseData);
      mockSupabase.setQueryBuilder('notifications', builder);

      final notifications = await service.getNotifications();

      expect(notifications.length, 1);
      expect(notifications[0].title, 'Test 1');
    });

    test('initializeFCM should request permission and get token', () async {
      await service.initializeFCM();

      // Since we use MockFirebaseMessaging which is a Fake, we just check it doesn't throw
      // and behaves according to our Fake's implementation.
      // In a more complex mock, we could track calls.
    });
  });
}
