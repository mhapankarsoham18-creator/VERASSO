
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:verasso/core/utils/logger.dart';

/// Top-level background handler required by firebase_messaging.
/// Must be a top-level function, NOT inside a class.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    'verasso_messages',
    'Secure Messages',
    channelDescription: 'Encrypted message notifications from Verasso',
    importance: Importance.high,
    priority: Priority.high,
  );
  const notifDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    id: message.hashCode,
    title: message.notification?.title ?? 'New Secure Message',
    body: message.notification?.body ?? 'You have a new encrypted message.',
    notificationDetails: notifDetails,
  );
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> initPushNotifications() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications for foreground display
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotif.initialize(settings: initSettings);

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

      // Handle foreground messages — spawn a visible local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        appLogger.d('Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'verasso_messages',
      'Secure Messages',
      channelDescription: 'Encrypted message notifications from Verasso',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    await _localNotif.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Secure Message',
      body: message.notification?.body ?? 'You have a new encrypted message.',
      notificationDetails: notifDetails,
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').update({'fcm_token': token})
          .eq('firebase_uid', user.uid);
    } catch (e) {
      appLogger.d('Failed to save FCM token: $e');
    }
  }
}

