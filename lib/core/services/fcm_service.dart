import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // Setup local notifications for foreground alerts
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'metro_institute_channel',
                'Metro Institute Notifikasi',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize FCM Service: $e');
    }
  }

  /// Sync device FCM token to Railway backend
  static Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM Device Token: $token');
        await ApiClient.dio.post(
          '/users/fcm-token',
          data: {'token': token},
        );
        debugPrint('FCM Device Token successfully synced to Railway backend.');
      }
    } catch (e) {
      debugPrint('FCM token sync error (non-fatal): $e');
    }
  }
}
