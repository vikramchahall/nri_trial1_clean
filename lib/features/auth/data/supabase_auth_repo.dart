import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';

class SupabaseAuthRepo implements AuthRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= LOGIN =================
  @override
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) return null;

      return await getCurrentUser();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= REGISTER =================
  @override
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String username,
    required String userType,
    String city = '',
    String town = '',
    String block = '',
    String panchayatId = '',
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      // 1️⃣ CHECK UNIQUE USERNAME
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', normalizedUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception("Username already taken");
      }

      // 2️⃣ SIGN UP (Supabase auto-sends verification email)
      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) return null;

      // 3️⃣ CREATE PROFILE ROW
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email.trim(),
        'username': normalizedUsername,
        'user_type': userType,
        'city': city,
        'town': town,
        'block_name': block,
        'panchayat_id': panchayatId,
        'is_admin': false,
        'is_dc': false,
      });

      // 4️⃣ FORCE LOGOUT → wait for email verification
      await _supabase.auth.signOut();

      return null; // triggers NeedVerification state
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= CURRENT USER =================
  @override
  Future<AppUser?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final user = session.user;

    // 🚫 BLOCK UNVERIFIED USERS
    if (user.emailConfirmedAt == null) {
      await _supabase.auth.signOut();
      return null;
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return AppUser.fromJson(data);
  }

  // ================= PASSWORD RESET =================
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw Exception("Reset error: ${e.toString()}");
    }
  }

  // ================= EMAIL VERIFICATION =================
  // Supabase handles verification automatically
  @override
  Future<void> sendEmailVerification() async {
    return;
  }

  @override
  Future<bool> checkEmailVerified() async {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  // ================= LOGOUT =================
  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
