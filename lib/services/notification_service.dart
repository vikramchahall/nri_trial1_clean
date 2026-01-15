import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static const String _projectId = 'sevapani-e660c';
  static const String _serviceAccountPath = 'assets/service_account.json';

  // =====================================
  // 1️⃣ INITIALIZE FCM + LOCAL NOTIFICATIONS
  // =====================================
  Future<void> initialize() async {
    // ✅ Initialize Local Notifications
    await _initializeLocalNotifications();

    // Request notification permissions (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token for this device
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('🔔 FCM Token: $token');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
    });

    // ✅ Handle FOREGROUND notifications (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground notification: ${message.notification?.title}');
      
      // Show local notification with sound/vibration
      _showLocalNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification tapped (background): ${message.data}');
      // Navigate to specific screen based on message.data
    });

    // Handle notification tap when app was completely closed
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📱 Notification tapped (terminated): ${initialMessage.data}');
      // Navigate to specific screen
    }
  }

  // =====================================
  // 🔔 INITIALIZE LOCAL NOTIFICATIONS
  // =====================================
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
        // Handle notification tap - navigate to relevant screen
      },
    );

    // ✅ Create Android notification channel (REQUIRED for Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // Must match the one in your FCM payload
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // =====================================
  // 🔔 SHOW LOCAL NOTIFICATION
  // =====================================
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // =====================================
  // 2️⃣ GET OAUTH2 ACCESS TOKEN
  // =====================================
  Future<String> _getAccessToken() async {
    try {
      final serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
      
      final accountCredentials = ServiceAccountCredentials.fromJson(
        json.decode(serviceAccountJson),
      );

      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      
      final accessToken = client.credentials.accessToken.data;
      
      client.close();
      
      return accessToken;
    } catch (e) {
      debugPrint('❌ Error getting access token: $e');
      rethrow;
    }
  }

  // =====================================
  // 3️⃣ SEND NOTIFICATION TO ONE DEVICE
  // =====================================
  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'high_importance_channel',
              'default_vibrate_timings': true,
              'notification_priority': 'PRIORITY_HIGH',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
                'alert': {
                  'title': title,
                  'body': body,
                },
              },
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  // =====================================
  // 4️⃣ SEND NOTIFICATION TO MULTIPLE DEVICES
  // =====================================
  Future<Map<String, int>> sendBulkPushNotifications({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    int sent = 0;
    int failed = 0;

    for (String token in deviceTokens) {
      final success = await sendPushNotification(
        deviceToken: token,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        sent++;
      } else {
        failed++;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    return {'sent': sent, 'failed': failed};
  }
}