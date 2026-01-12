import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// 🔹 AUTH (SUPABASE)
import 'features/auth/data/supabase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/verification_page.dart';
import 'features/auth/presentation/pages/reset_password_otp_page.dart';

// 🔹 LANGUAGE
import 'features/auth/presentation/cubits/language_cubit.dart';

// 🔹 CROWDFUNDING (SUPABASE)
import 'features/crowdfunding/data/supabase_crowd_repo.dart';
import 'features/crowdfunding/presentation/cubits/crowd_cubit.dart';

// 🔹 PROFILE (SUPABASE)
import 'features/profile/data/supabase_profile_repo.dart';
import 'features/profile/presentation/cubits/profile_cubit.dart';

// 🔹 STORAGE
import 'features/storage/data/supabase_storage_repo.dart';

// 🔹 HOME
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INITIALIZE SUPABASE
  await supa.Supabase.initialize(
    url: 'https://hjvsxridquolfrddlbpp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnN4cmlkcXVvbGZyZGRsYnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxMDMxNTEsImV4cCI6MjA4MzY3OTE1MX0.-54QtJFfCLbDQCnEaAApSFjCHm2IkIdokV2LuroevCE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🌐 LANGUAGE
        BlocProvider(create: (_) => LanguageCubit()),

        // 🔐 AUTH
        BlocProvider(
          create: (_) => AuthCubit(
            authRepo: SupabaseAuthRepo(),
          )..checkAuth(),
        ),

        // ❤️ CROWDFUNDING
        BlocProvider(
          create: (_) => CrowdCubit(
            crowdRepo: SupabaseCrowdRepo(),
            storageRepo: SupabaseStorageRepo(),
          ),
        ),

        // 👤 PROFILE
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

        // 🔁 AUTH STATE HANDLING (NO LOGIN FLASH)
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
            // ✅ 0️⃣ SPLASH / CHECKING SESSION (FIXES LOGIN FLASH)
            if (state is AuthInitial) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            // 1️⃣ LOGGED IN
            if (state is Authenticated) {
              return const HomePage();
            }

            // 2️⃣ 🔐 RESET PASSWORD (OTP SCREEN)
            if (state is ResetPasswordOtpMode) {
              return ResetPasswordOtpPage(email: state.email);
            }

            // 3️⃣ EMAIL VERIFICATION
            if (state is NeedVerification) {
              return VerificationPage(email: state.email);
            }

            // 4️⃣ LOADING (API CALLS)
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            // 5️⃣ DEFAULT → LOGIN / REGISTER
            return const AuthPage();
          },
        ),
      ),
    );
  }
}
