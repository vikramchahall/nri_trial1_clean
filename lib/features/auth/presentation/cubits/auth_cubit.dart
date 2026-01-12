import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  // 🔑 Variables to remember for LOGIN AUTO-FILL
  String? prefillEmail;
  String? prefillPassword;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  AppUser? get currentUser => _currentUser;

  // ==================================================
  // CHECK AUTH (APP START)
  // ==================================================
  Future<void> checkAuth() async {
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  // ==================================================
  // LOGIN (MANUAL)
  // ==================================================
  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());

      final user =
          await authRepo.loginWithEmailPassword(email, password);

      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      _currentUser = user;

      // Clear auto-fill after successful login
      prefillEmail = null;
      prefillPassword = null;

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // REGISTER → SAVE FOR AUTO-FILL (NO AUTO LOGIN)
  // ==================================================
  Future<void> registerUser({
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
      emit(AuthLoading());

      await authRepo.registerUser(
        email: email,
        password: password,
        username: username,
        userType: userType,
        city: city,
        town: town,
        block: block,
        panchayatId: panchayatId,
      );

      // 💾 SAVE FOR LOGIN AUTO-FILL
      prefillEmail = email;
      prefillPassword = password;

      emit(NeedVerification(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // EMAIL VERIFICATION CHECK (RETURN TO LOGIN)
  // ==================================================
  Future<void> checkStatus(String email) async {
    try {
      final isVerified = await authRepo.checkEmailVerified();

      if (isVerified) {
        emit(Unauthenticated());
        emit(AuthError("Email verified! You can now login."));
      } else {
        emit(NeedVerification(email));
        emit(AuthError("Check Gmail! Link not clicked yet."));
      }
    } catch (_) {
      emit(NeedVerification(email));
      emit(AuthError("System busy. Try again."));
    }
  }

  // ✅ ALIAS
  Future<void> checkVerificationStatus(String email) {
    return checkStatus(email);
  }

  // ==================================================
  // 🔐 SHOW PASSWORD RESET SCREEN (LEGACY)
  // ==================================================
  void showPasswordResetScreen() {
    emit(PasswordRecoveryMode());
  }

  // ==================================================
  // UPDATE PASSWORD (LOGGED-IN USER)
  // ==================================================
  Future<void> updatePassword(String newPassword) async {
    try {
      emit(AuthLoading());
      await authRepo.updatePassword(newPassword);

      emit(Unauthenticated());
      emit(AuthError(
        "Password updated! Please login with your new password.",
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // 🔐 FORGOT PASSWORD → SEND OTP + FORCE OTP SCREEN
  // (STEP-2 FIX APPLIED HERE)
  // ==================================================
  Future<void> forgotPassword(String email) async {
    try {
      emit(AuthLoading()); // show loader

      // 1. Ask Supabase to send OTP
      await authRepo.sendPasswordResetEmail(email.trim());

      // 2. FORCE state change to OTP mode
      emit(ResetPasswordOtpMode(email.trim()));
    } catch (e) {
      // On failure → back to login + error
      emit(Unauthenticated());
      emit(AuthError(
        "User not found or limit exceeded: ${e.toString()}",
      ));
    }
  }

  // ==================================================
  // 🔐 VERIFY OTP + RESET PASSWORD
  // ==================================================
  Future<void> verifyAndReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      emit(AuthLoading());

      await authRepo.verifyOtpAndSetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      emit(Unauthenticated());
      emit(AuthError("Password reset successful! Please login."));
    } catch (e) {
      emit(ResetPasswordOtpMode(email));
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // BACK TO LOGIN
  // ==================================================
  void goToLogin() {
    emit(Unauthenticated());
  }

  // ==================================================
  // LOGOUT
  // ==================================================
  Future<void> logout() async {
    await authRepo.logout();
    _currentUser = null;
    emit(Unauthenticated());
  }
}
