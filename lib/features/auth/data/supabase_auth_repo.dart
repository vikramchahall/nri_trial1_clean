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

      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', normalizedUsername)
          .maybeSingle();

      if (existing != null) {
        throw Exception("Username already taken");
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) return null;

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

      await _supabase.auth.signOut();
      return null;
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

  // ================= PASSWORD RESET (SEND OTP) =================
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // ✅ CORRECT: sends 6-digit OTP using email template
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  // ================= VERIFY OTP & SET PASSWORD =================
  @override
  Future<void> verifyOtpAndSetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: OtpType.recovery,
    );

    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ================= UPDATE PASSWORD (LOGGED IN) =================
  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ================= EMAIL VERIFICATION =================
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
