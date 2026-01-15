import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepo implements AuthRepo {
  final SupabaseClient _supabase = Supabase.instance.client;
final SupabaseClient supabase = Supabase.instance.client;

  @override
Future<void> resendVerificationEmail(String email) async {
  try {
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  } catch (e) {
    throw Exception('Failed to resend verification email: ${e.toString()}');
  }
}

  // ===============================
  // 👤 GET CURRENT USER (FRESH DATA)
  // ===============================
  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // 🔥 SINGLE QUERY WITH JOINS (NO CACHE)
      final response = await _supabase
          .from('profiles')
          .select(
            '*, '
            'follows!following_id(follower_id), '
            'following:follows!follower_id(following_id)',
          )
          .eq('id', user.id)
          .single();

      // Followers
      final List followersRaw = response['follows'] ?? [];
      final List<String> followerIds = followersRaw
          .map((f) => f['follower_id'].toString())
          .toList();

      // Following
      final List followingRaw = response['following'] ?? [];
      final List<String> followingIds = followingRaw
          .map((f) => f['following_id'].toString())
          .toList();

      return AppUser.fromJson({
        ...response,
        'followers': followerIds,
        'following': followingIds,
      });
    } catch (e) {
      debugPrint('❌ getCurrentUser error: $e');
      return null;
    }
  }

  // ===============================
  // 🔐 LOGIN
  // ===============================
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
      throw Exception('Login failed: $e');
    }
  }

  // ===============================
  // 📝 REGISTER
  // ===============================
@override
Future<AppUser?> registerUser({
  required String email,
  required String password,
  required String username,
  required String phone,
  required String userType,
  String city = '',
  String town = '',
  String block = '',
  String panchayatId = '',
}) async {
  try {
    final normalizedUsername = username.trim().toLowerCase();

    // 🔍 Username uniqueness check
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', normalizedUsername)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Username already taken. Please choose another.');
    }

    // 🔐 Auth signup
    final res = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'io.supabase.nri://login-callback/',
    );

    final user = res.user;
    if (user == null) throw Exception('User creation failed');

    // 🧾 Profile insert
    await _supabase.from('profiles').insert({
      'id': user.id,
      'email': email.trim(),
      'username': normalizedUsername,
      'phone': phone,
      'user_type': userType,
      'city': city,
      'town': town,
      'block_name': block,
      'panchayat_id': panchayatId,
      'bio': '',
      'profile_image_url': '',
      'image_version': 0,
      'is_admin': false,
      'is_dc': false,
    });

    // 🚪 Force email verification
    await _supabase.auth.signOut();
    return null;

  } on AuthException catch (e) {
    // ✅ Handle Supabase Auth errors
    if (e.message.toLowerCase().contains('already registered') ||
        e.message.toLowerCase().contains('user already exists')) {
      throw Exception('Email already registered. Please try Forgot Password.');
    } else if (e.message.toLowerCase().contains('invalid email')) {
      throw Exception('Please enter a valid email address.');
    } else if (e.message.toLowerCase().contains('weak password')) {
      throw Exception('Password is too weak. Use at least 6 characters.');
    } else {
      throw Exception('Registration failed: ${e.message}');
    }
    
  } on PostgrestException catch (e) {
    // ✅ Handle Database errors - DUPLICATE KEY FIX
    if (e.message.toLowerCase().contains('duplicate key') ||
        e.message.toLowerCase().contains('profiles_pkey') ||
        e.code == '23505') {
      throw Exception('Email already registered. Please try Forgot Password.');
    } else if (e.message.toLowerCase().contains('violates check constraint')) {
      throw Exception('Invalid data provided. Please check your inputs.');
    } else {
      throw Exception('Registration failed. Please try again.');
    }
    
  } catch (e) {
    // ✅ Handle any other errors
    final errorMsg = e.toString().toLowerCase();
    
    if (errorMsg.contains('username already taken')) {
      throw Exception('Username already taken. Please choose another.');
    } else if (errorMsg.contains('duplicate') || 
               errorMsg.contains('already registered')) {
      throw Exception('Email already registered. Please try Forgot Password.');
    } else {
      throw Exception('Registration failed. Please try again.');
    }
  }
}

  // ===============================
  // 📧 EMAIL VERIFIED?
  // ===============================
  @override
  Future<bool> checkEmailVerified() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.auth.refreshSession();
      final refreshedUser = _supabase.auth.currentUser;

      return refreshedUser?.emailConfirmedAt != null;
    } catch (_) {
      return false;
    }
  }

  // ===============================
  // 🔑 PASSWORD RESET
  // ===============================
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  // ===============================
  // 🔄 UPDATE PASSWORD
  // ===============================
  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ===============================
  // 🔐 VERIFY OTP + SET PASSWORD
  // ===============================
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

  // ===============================
  // 🗑️ DELETE ACCOUNT
  // ===============================
  @override
  Future<void> deleteAccount(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final email = user.email;
      if (email == null) throw Exception('Email not found');

      // 🔐 Re-auth
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 🧾 Delete profile
      await _supabase.from('profiles').delete().eq('id', user.id);

      // 🗑️ Delete auth user
      await _supabase.rpc('delete_user');

      // 🚪 Logout
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Incorrect password');
      }
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Account deletion failed');
    }
  }

  // ===============================
  // 🚪 LOGOUT
  // ===============================
  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ===============================
  // 📩 EMAIL VERIFICATION (NO-OP)
  // ===============================
  @override
  Future<void> sendEmailVerification() async {
    return;
  }
}
