import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  /// 1️⃣ Initialize FCM and save token to Supabase
  static Future<void> initialize() async {
    try {
      // Request permission (iOS only, Android auto-grants)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ User denied notification permissions');
        return;
      }

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        print('✅ FCM Token: $token');
        await _saveFCMTokenToSupabase(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMTokenToSupabase);

      // Setup foreground notification handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Setup notification tap handler (when app is in background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      print('✅ FCM Initialized');
    } catch (e) {
      print('❌ FCM Error: $e');
    }
  }

  /// 2️⃣ Save FCM token to Supabase profiles table
  static Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'fcm_token': token,
      }).eq('id', userId);

      print('✅ FCM token saved to Supabase');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// 3️⃣ Handle foreground notifications (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground notification: ${message.notification?.title}');
    
    // You can show a custom in-app notification here
    // Or let the system notification show automatically
  }

  /// 4️⃣ Handle notification tap (when user taps notification)
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 User tapped notification: ${message.notification?.title}');
    
    // Navigate to specific screen based on notification data
    final data = message.data;
    if (data['type'] == 'admin_notification') {
      // Navigate to notifications screen or specific page
      print('Navigate to: ${data['type']}');
    }
  }

  /// 5️⃣ Remove FCM token on logout
  static Future<void> removeToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'fcm_token': null,
      }).eq('id', userId);

      await _fcm.deleteToken();
      print('✅ FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }
}