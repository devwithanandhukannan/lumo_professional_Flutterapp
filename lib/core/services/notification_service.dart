import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../network/pro_api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log("Handling Pro background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lumo_pro_high_importance_channel',
    'LUMO Pro Job Alerts',
    description: 'Used for new job requests, booking updates, and safety alerts.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log('Pro notification permission status: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Initialize Local Notifications Plugin FIRST (required before any platform-specific calls)
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Pro foreground notification tapped: ${response.payload}');
      },
    );

    // 5. Now request Android 13+ notification permission & create channel (after init)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log("Received Pro foreground message: ${message.notification?.title}");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Listen for Token Refresh (re-sync when token rotates)
    _messaging.onTokenRefresh.listen((newToken) {
      ProApiClient.updateFcmToken(newToken);
    });
    // NOTE: Initial FCM token sync happens in syncFcmTokenAfterLogin() after user authenticates
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      developer.log("Pro FCM Device Token: $token");
      return token;
    } catch (e) {
      developer.log("Error fetching Pro FCM token: $e");
      return null;
    }
  }

  /// Call this immediately after the professional successfully logs in / authenticates.
  /// Uploads the current FCM token to the backend so push notifications work.
  static Future<void> syncFcmTokenAfterLogin() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        developer.log("Syncing Pro FCM token to backend after login: ${token.substring(0, 20)}...");
        await ProApiClient.updateFcmToken(token);
      }
    } catch (e) {
      developer.log("Error syncing Pro FCM token after login: $e");
    }
  }

  static void _handleMessageOpened(RemoteMessage message) {
    developer.log("Pro Notification opened with data: ${message.data}");
  }
}
