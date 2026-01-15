import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

// Import your existing files
import 'features/auth/data/supabase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/verification_page.dart';
import 'features/auth/presentation/pages/reset_password_otp_page.dart';
import 'core/config/app_env.dart';
import 'features/auth/presentation/cubits/language_cubit.dart';
import 'features/crowdfunding/data/supabase_crowd_repo.dart';
import 'features/crowdfunding/presentation/cubits/crowd_cubit.dart';
import 'features/profile/data/supabase_profile_repo.dart';
import 'features/profile/presentation/cubits/profile_cubit.dart';
import 'features/storage/data/supabase_storage_repo.dart';
import 'features/home/presentation/pages/home_page.dart';

// 🔔 BACKGROUND MESSAGE HANDLER (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📩 Background message: ${message.notification?.title}');
}

// ✅ SAVE FCM TOKEN TO SUPABASE
Future<void> _saveFcmToken(String token) async {
  try {
    final userId = supa.Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await supa.Supabase.instance.client.from('fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'device_type': 'mobile',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,token');

    debugPrint('✅ FCM token saved to database');
  } catch (e) {
    debugPrint('❌ Failed to save FCM token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1️⃣ Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 2️⃣ Setup FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 3️⃣ Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // 4️⃣ Get FCM Token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      debugPrint('🔔 FCM Token: $fcmToken');
      // Token will be saved after user logs in
    }
    
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
  }

  // 5️⃣ Initialize Supabase
  await supa.Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(
          create: (_) => AuthCubit(
            authRepo: SupabaseAuthRepo(),
          )..checkAuth(),
        ),
        BlocProvider(
          create: (_) => CrowdCubit(
            crowdRepo: SupabaseCrowdRepo(),
            storageRepo: SupabaseStorageRepo(),
          ),
        ),
        BlocProvider(
          create: (_) => ProfileCubit(
            profileRepo: SupabaseProfileRepo(),
            storageRepo: SupabaseStorageRepo(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) async {
            // ✅ Save FCM token when user logs in
            if (state is Authenticated) {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                await _saveFcmToken(token);
              }
            }
            
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthInitial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            if (state is Authenticated) {
              return const HomePage();
            }

            if (state is ResetPasswordOtpMode) {
              return ResetPasswordOtpPage(email: state.email);
            }

            if (state is NeedVerification) {
              return VerificationPage(
                email: state.email,
                password: state.password,
              );
            }

            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            return const AuthPage();
          },
        ),
      ),
    );
  }
}