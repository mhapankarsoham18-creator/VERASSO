import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/notifications/data/notification_service.dart';
import 'package:verasso/features/notifications/models/notification_model.dart';

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
    group('markAllAsRead', () {
      test('should call update on notifications table', () async {
        mockSupabaseClient.setRpcResponse('mark_notifications_read', null);
        await service.markAllAsRead();
        // Verifies no exception thrown — the mock handles the table query
      });
    });

    group('markAsRead', () {
      test('should update a specific notification by ID', () async {
        await service.markAsRead('notification-123');
        // Verifies the update call completes without error
      });
    });

    group('getNotifications', () {
      test('should return empty list when no notifications exist', () async {
        final notifications = await service.getNotifications();
        expect(notifications, isNotNull);
        expect(notifications, isEmpty);
      });

      test('returns List<NotificationModel>', () async {
        final notifications = await service.getNotifications();
        expect(notifications, isA<List<NotificationModel>>());
      });
    });

    group('createNotification', () {
      test('should create a notification without error', () async {
        await service.createNotification(
          targetUserId: 'user-123',
          type: NotificationType.socialInteraction,
          title: 'Test Notification',
          body: 'This is a test notification body',
        );
        // No exception means success
      });

      test('should handle optional data parameter', () async {
        await service.createNotification(
          targetUserId: 'user-456',
          type: NotificationType.system,
          title: 'System Alert',
          body: 'System maintenance scheduled',
          data: {'priority': 'high', 'category': 'maintenance'},
        );
      });
    });

    group('sendJobNotification', () {
      test('should create a job notification using createNotification',
          () async {
        await service.sendJobNotification(
          userId: 'user-789',
          title: 'New Job Match',
          message: 'A new job matching your skills is available',
          jobId: 'job-001',
        );
      });
    });
  });

  group('NotificationType', () {
    test('has expected values', () {
      expect(NotificationType.values, isNotEmpty);
    });

    test('has social type', () {
      expect(NotificationType.values.map((e) => e.name),
          contains('socialInteraction'));
    });

    test('has system type', () {
      expect(NotificationType.values.map((e) => e.name), contains('system'));
    });
  });
}
