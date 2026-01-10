import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// 🔹 AUTH
import 'features/auth/data/firebase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/verification_page.dart';

// 🔹 LANGUAGE
import 'features/auth/presentation/cubits/language_cubit.dart';

// 🔹 CROWDFUNDING
import 'features/crowdfunding/data/firebase_crowd_repo.dart';
import 'features/crowdfunding/presentation/cubits/crowd_cubit.dart';

// 🔹 STORAGE
import 'features/storage/data/supabase_storage_repo.dart';

// 🔹 PROFILE
import 'features/profile/data/firebase_profile_repo.dart';
import 'features/profile/presentation/cubits/profile_cubit.dart';

// 🔹 HOME
import 'features/home/presentation/pages/home_page.dart';

// 🔹 FIREBASE OPTIONS
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await supabase.Supabase.initialize(
    url: 'https://chpmwhtzivhcttwpjqwc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNocG13aHR6aXZoY3R0d3BqcXdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4NDk2NjAsImV4cCI6MjA4MjQyNTY2MH0.iNRfI7VXN4WsX6hMk1ubGpFZHIejKnltNY3h2o6FFHE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = FirebaseAuthRepo();
    final crowdRepo = FirebaseCrowdRepo();
    final profileRepo = FirebaseProfileRepo();
    final storageRepo = SupabaseStorageRepo();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(create: (_) => AuthCubit(authRepo: authRepo)..checkAuth()),
        BlocProvider(
          create: (_) => CrowdCubit(
            crowdRepo: crowdRepo,
            storageRepo: storageRepo,
          ),
        ),
        BlocProvider(
          create: (_) => ProfileCubit(
            profileRepo: profileRepo,
            storageRepo: storageRepo,
          ),
        ),
      ],
      child: BlocBuilder<LanguageCubit, AppLanguage>(
        builder: (context, language) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // 🌐 LANGUAGE CONTROL
            locale: _mapLanguageToLocale(language),

            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('pa'),
            ],

            // ✅ THIS FIXES ALL ERRORS
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
            ),

            home: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
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
                if (state is Authenticated) {
                  return const HomePage();
                }

                if (state is NeedVerification) {
                  return VerificationPage(email: state.email);
                }

                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return const AuthPage();
              },
            ),
          );
        },
      ),
    );
  }
}

// ================= LANGUAGE → LOCALE MAPPER =================
Locale _mapLanguageToLocale(AppLanguage language) {
  switch (language) {
    case AppLanguage.hindi:
      return const Locale('hi');
    case AppLanguage.punjabi:
      return const Locale('pa');
    case AppLanguage.english:
    default:
      return const Locale('en');
  }
}
