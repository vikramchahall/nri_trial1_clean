import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

import 'features/auth/data/supabase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'package:nri_trial1_clean/features/auth/presentation/pages/verification_page.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';
import 'features/auth/presentation/pages/reset_password_otp_page.dart';
import 'core/config/app_env.dart';
import 'features/auth/presentation/cubits/language_cubit.dart';
import 'features/crowdfunding/data/supabase_crowd_repo.dart';
import 'features/crowdfunding/presentation/cubits/crowd_cubit.dart';
import 'features/crowdfunding/presentation/pages/post_detail_page.dart';
import 'features/profile/data/supabase_profile_repo.dart';
import 'features/profile/presentation/cubits/profile_cubit.dart';
import 'features/profile/presentation/pages/user_profile_page.dart';
import 'features/storage/data/supabase_storage_repo.dart';
import 'features/home/presentation/pages/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _pendingPostId;
String? _pendingProfileUid;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message: ${message.notification?.title}');
}

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
    debugPrint('✅ FCM token saved');
  } catch (e) {
    debugPrint('❌ FCM token save failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final notificationService = NotificationService();
    await notificationService.initialize();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) debugPrint('🔔 FCM Token: $fcmToken');
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  await supa.Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('🔗 Initial deep link: $initialLink');
      _handleLink(initialLink);
    }

    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Deep link received: $uri');
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    String? postId;
    String? profileUid;

    // connectnri://post/POST_ID
    if (uri.scheme == 'connectnri' && uri.host == 'post') {
      postId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // connectnri://profile/UID
    else if (uri.scheme == 'connectnri' && uri.host == 'profile') {
      profileUid = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // https://connect-nri.github.io/connectnri/?post=ID or ?profile=UID
    else if (uri.host == 'connect-nri.github.io' &&
        uri.path.startsWith('/connectnri')) {
      postId = uri.queryParameters['post'];
      profileUid = uri.queryParameters['profile'];
    }

    final navState = navigatorKey.currentState;

    if (postId != null) {
      if (navState != null && navState.mounted) {
        navState.push(MaterialPageRoute(
          builder: (_) => DeepLinkPostLoader(postId: postId!),
        ));
      } else {
        debugPrint('⏳ Storing pending post: $postId');
        _pendingPostId = postId;
      }
    }

    if (profileUid != null) {
      if (navState != null && navState.mounted) {
        navState.push(MaterialPageRoute(
          builder: (_) => UserProfilePage(uid: profileUid!),
        ));
      } else {
        debugPrint('⏳ Storing pending profile: $profileUid');
        _pendingProfileUid = profileUid;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(
          create: (_) => AuthCubit(authRepo: SupabaseAuthRepo())..checkAuth(),
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
        navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) async {
            if (state is Authenticated) {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) await _saveFcmToken(token);

              // ✅ Handle pending post deep link
              if (_pendingPostId != null) {
                final postId = _pendingPostId!;
                _pendingPostId = null;
                await Future.delayed(const Duration(milliseconds: 300));
                navigatorKey.currentState?.push(MaterialPageRoute(
                  builder: (_) => DeepLinkPostLoader(postId: postId),
                ));
              }

              // ✅ Handle pending profile deep link
              if (_pendingProfileUid != null) {
                final profileUid = _pendingProfileUid!;
                _pendingProfileUid = null;
                await Future.delayed(const Duration(milliseconds: 300));
                navigatorKey.currentState?.push(MaterialPageRoute(
                  builder: (_) => UserProfilePage(uid: profileUid),
                ));
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
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }
            if (state is Authenticated) return const HomePage();
            if (state is ResetPasswordOtpMode) {
              return ResetPasswordOtpPage(email: state.email);
            }
            if (state is NeedVerification) {
              return VerificationPage(
                email: state.email,
                password: state.password,
              );
            }
            return const AuthPage();
          },
        ),
      ),
    );
  }
}

// ===============================
// 🔗 DEEP LINK POST LOADER
// ===============================
class DeepLinkPostLoader extends StatefulWidget {
  final String postId;
  const DeepLinkPostLoader({super.key, required this.postId});

  @override
  State<DeepLinkPostLoader> createState() => _DeepLinkPostLoaderState();
}

class _DeepLinkPostLoaderState extends State<DeepLinkPostLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final post = await context.read<CrowdCubit>().getPostById(widget.postId);
      if (mounted) {
        Navigator.replace(
          context,
          oldRoute: ModalRoute.of(context)!,
          newRoute: MaterialPageRoute(
            builder: (_) => PostDetailPage(post: post),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Deep link post load failed: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't find that post. It may have been deleted."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text("Loading...",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}