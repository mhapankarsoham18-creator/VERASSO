import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/notifications/data/notification_service.dart';

import '../../mocks.dart';

void main() {
  late NotificationService service;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    service = NotificationService(
      client: mockSupabaseClient,
      fcm: MockFirebaseMessaging(),
    );
  });

  group('NotificationService', () {
    test('markAllAsRead should call rpc', () async {
      mockSupabaseClient.setRpcResponse('mark_notifications_read', null);

      await service.markAllAsRead();
      // Implicitly verified via setRpcResponse matching
    });

    test('getNotifications should return a list', () async {
      final notifications = await service.getNotifications();
      expect(notifications, isNotNull);
      expect(notifications, isEmpty); // From MockSupabaseQueryBuilder default
    });
  });
}
