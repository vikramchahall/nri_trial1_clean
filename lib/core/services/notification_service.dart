// 📁 Save this as: lib/core/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;

  // ========================================
  // 1️⃣ INITIALIZE LOCAL NOTIFICATIONS
  // ========================================
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  // ========================================
  // 2️⃣ SETUP FCM
  // ========================================
  static Future<void> setupFCM() async {
    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('📱 Permission: ${settings.authorizationStatus}');

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('🔔 FCM Token: ${token.substring(0, 20)}...');
    }

    // Setup handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground: ${message.notification?.title}');
      handleFCMMessage(message);
    });

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token refreshed');
      saveFCMToken();
    });

    // Notification tapped (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Tapped: ${message.notification?.title}');
      _handleNotificationData(message.data);
    });

    // Notification tapped (terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📲 Opened from terminated: ${initialMessage.notification?.title}');
      _handleNotificationData(initialMessage.data);
    }
  }

  // ========================================
  // 3️⃣ SAVE FCM TOKEN TO DATABASE
  // ========================================
  static Future<void> saveFCMToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot save token: User not logged in');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('⚠️ Cannot save token: No FCM token available');
        return;
      }

      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': 'mobile',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');

      debugPrint('✅ FCM token saved for user: ${userId.substring(0, 8)}...');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  // ========================================
  // 4️⃣ SHOW LOCAL NOTIFICATION
  // ========================================
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
    debugPrint('🔔 Notification shown: $title');
  }

  // ========================================
  // 5️⃣ HANDLE FCM MESSAGE
  // ========================================
  static Future<void> handleFCMMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showNotification(
      id: message.hashCode,
      title: notification.title ?? 'New Notification',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  // ========================================
  // 6️⃣ HANDLE NOTIFICATION TAP
  // ========================================
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Add your navigation logic here
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('📦 Notification data: $data');
    // Handle different notification types
    final type = data['type'];
    switch (type) {
      case 'announcement':
        // Navigate to announcements page
        break;
      case 'crowdfunding':
        // Navigate to crowdfunding details
        break;
      default:
        // Default action
        break;
    }
  }

  // ========================================
  // 7️⃣ DELETE FCM TOKEN (ON LOGOUT)
  // ========================================
  static Future<void> deleteFCMToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final token = await _messaging.getToken();
      
      if (userId != null && token != null) {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
        
        debugPrint('✅ FCM token deleted');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete FCM token: $e');
    }
  }
}

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background handler called');
}