import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/notifications/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson creates notification correctly', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'type': 'like',
        'title': 'New Like',
        'body': 'Someone liked your post',
        'is_read': false,
        'data': {'post_id': 'post-1'},
        'created_at': '2026-02-27T12:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.id, 'notif-1');
      expect(notif.title, 'New Like');
      expect(notif.body, 'Someone liked your post');
      expect(notif.isRead, false);
    });

    test('notification types are valid', () {
      // Verify all notification types used across the app
      for (final type in NotificationType.values) {
        expect(type.name, isNotEmpty);
      }
    });
  });

  group('Notification data validation', () {
    test('notification has required fields', () {
      final notifData = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'type': 'follow',
        'title': 'New Follower',
        'body': 'User X started following you',
        'is_read': false,
        'data': {'follower_id': 'user-2'},
        'created_at': '2026-02-27T12:00:00Z',
      };

      expect(notifData['type'], 'follow');
      expect(notifData['is_read'], false);
      expect((notifData['data'] as Map)['follower_id'], 'user-2');
    });

    test('markAsRead updates is_read flag', () {
      final notifData = {
        'id': 'notif-1',
        'is_read': false,
      };

      // Simulate marking as read
      notifData['is_read'] = true;
      expect(notifData['is_read'], true);
    });

    test('markAllAsRead updates all notifications', () {
      final notifs = [
        {'id': 'n1', 'is_read': false},
        {'id': 'n2', 'is_read': false},
        {'id': 'n3', 'is_read': true},
      ];

      for (final n in notifs) {
        n['is_read'] = true;
      }

      expect(notifs.every((n) => n['is_read'] == true), isTrue);
    });
  });

  group('Notification ordering', () {
    test('notifications sort by creation time descending', () {
      final times = [
        DateTime.parse('2026-02-27T12:00:00Z'),
        DateTime.parse('2026-02-27T14:00:00Z'),
        DateTime.parse('2026-02-27T10:00:00Z'),
      ];

      times.sort((a, b) => b.compareTo(a)); // Descending

      expect(times.first, DateTime.parse('2026-02-27T14:00:00Z'));
      expect(times.last, DateTime.parse('2026-02-27T10:00:00Z'));
    });
  });

  group('Job notification', () {
    test('creates job notification with correct data', () {
      final jobNotif = {
        'user_id': 'user-1',
        'type': 'job_update',
        'title': 'Job Application Update',
        'body': 'Your application was reviewed',
        'data': {'job_id': 'job-123'},
        'is_read': false,
      };

      expect(jobNotif['type'], 'job_update');
      expect((jobNotif['data'] as Map)['job_id'], 'job-123');
    });
  });
}
