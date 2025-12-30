import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// 🔹 AUTH
import 'features/auth/data/firebase_auth_repo.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/cubits/auth_states.dart';
import 'features/auth/presentation/pages/auth_page.dart';

// 🔹 CROWDFUNDING
import 'features/crowdfunding/data/firebase_crowd_repo.dart';
import 'features/crowdfunding/presentation/cubits/crowd_cubit.dart';

// 🔹 STORAGE
import 'features/storage/data/supabase_storage_repo.dart';

// 🔹 HOME
import 'features/home/presentation/pages/home_page.dart';

// 🔹 FIREBASE OPTIONS
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Supabase init
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
    return MultiBlocProvider(
      providers: [
        // 🔹 AUTH CUBIT
        BlocProvider(
          create: (context) =>
              AuthCubit(authRepo: FirebaseAuthRepo())..checkAuth(),
        ),

        // 🔹 CROWD CUBIT
        BlocProvider(
          create: (context) => CrowdCubit(
            crowdRepo: FirebaseCrowdRepo(),
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

        // 🔥 ROUTE DECISION BASED ON AUTH
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            // ✅ Logged in
            if (state is Authenticated) {
              return const HomePage();
            }

            // ⏳ Loading
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ❌ Not logged in
            return const AuthPage();
          },
        ),
      ),
    );
  }
}
