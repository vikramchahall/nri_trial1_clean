import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_states.dart';
import 'package:nri_trial1_clean/core/services/fcm_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

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
        await FCMService.initialize();
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

      final user = await authRepo.loginWithEmailPassword(email, password);

      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      _currentUser = user;
      prefillEmail = null;
      prefillPassword = null;

      await FCMService.initialize();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // REGISTER
  // ==================================================
  Future<void> registerUser({
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
      emit(AuthLoading());

      await authRepo.registerUser(
        email: email,
        password: password,
        username: username,
        phone: phone,
        userType: userType,
        city: city,
        town: town,
        block: block,
        panchayatId: panchayatId,
      );

      prefillEmail = email;
      prefillPassword = password;
      emit(NeedVerification(email: email, password: password));

    } catch (e) {
      final errorMsg = e.toString().toLowerCase();

      // ✅ Unverified email — resend and go to verification page
      if (e.toString().contains('__UNVERIFIED__')) {
        prefillEmail = email;
        prefillPassword = password;
        emit(NeedVerification(email: email, password: password));
        return;
      }

      if (errorMsg.contains('already registered') ||
          errorMsg.contains('user already registered')) {
        emit(AuthError(
          "This email is already registered.\n"
          "Use 'Forgot Password' to recover your account.",
        ));
      } else if (errorMsg.contains('email not confirmed') ||
                 errorMsg.contains('email unconfirmed')) {
        emit(AuthError(
          "Email already registered but not verified.\n"
          "Check your inbox/spam for verification link.",
        ));
      } else {
        emit(AuthError(e.toString().replaceAll("Exception: ", "")));
      }
    }
  }

  // ==================================================
  // RESEND VERIFICATION EMAIL
  // ==================================================
  Future<void> resendVerification(String email) async {
    try {
      await authRepo.resendVerificationEmail(email);
      emit(NeedVerification(email: email, password: prefillPassword));
    } catch (e) {
      emit(NeedVerification(email: email, password: prefillPassword));
      emit(AuthError("Could not resend email. Try again in 60 seconds."));
    }
  }

  // ==================================================
  // EMAIL VERIFICATION CHECK
  // ==================================================
  Future<void> checkStatus(String email) async {
    try {
      final isVerified = await authRepo.checkEmailVerified();

      if (isVerified) {
        emit(Unauthenticated());
        emit(AuthError("Email verified! You can now login."));
      } else {
        emit(NeedVerification(email: email, password: prefillPassword));
        emit(AuthError("Check Gmail! Link not clicked yet."));
      }
    } catch (_) {
      emit(NeedVerification(email: email, password: prefillPassword));
      emit(AuthError("System busy. Try again."));
    }
  }

  Future<void> checkVerificationStatus(String email) {
    return checkStatus(email);
  }

  // ==================================================
  // PASSWORD RESET UI
  // ==================================================
  void showPasswordResetScreen() {
    emit(PasswordRecoveryMode());
  }

  // ==================================================
  // UPDATE PASSWORD
  // ==================================================
  Future<void> updatePassword(String newPassword) async {
    try {
      emit(AuthLoading());
      await authRepo.updatePassword(newPassword);
      emit(Unauthenticated());
      emit(AuthError("Password updated! Please login with your new password."));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // FORGOT PASSWORD
  // ==================================================
  Future<void> forgotPassword(String email) async {
    try {
      emit(AuthLoading());
      await authRepo.sendPasswordResetEmail(email.trim());
      emit(ResetPasswordOtpMode(email.trim()));
    } catch (e) {
      emit(Unauthenticated());
      emit(AuthError("User not found or limit exceeded: ${e.toString()}"));
    }
  }

  // ==================================================
  // VERIFY OTP
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
  // 🔄 REFRESH CURRENT USER
  // ==================================================
  Future<void> refreshCurrentUser() async {
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
    } catch (e) {
      debugPrint("Error refreshing current user: $e");
    }
  }

  // ==================================================
  // BACK TO LOGIN
  // ==================================================
  void goToLogin() {
    emit(Unauthenticated());
  }

  // ==================================================
  // DELETE ACCOUNT
  // ==================================================
  Future<void> deleteAccount(String password) async {
    try {
      emit(AuthLoading());
      await FCMService.removeToken();
      await authRepo.deleteAccount(password);
      _currentUser = null;
      emit(Unauthenticated());
    } catch (e) {
      if (_currentUser != null) {
        emit(Authenticated(_currentUser!));
      } else {
        emit(Unauthenticated());
      }
      rethrow;
    }
  }

  // ==================================================
  // LOGOUT
  // ==================================================
  Future<void> logout() async {
    await FCMService.removeToken();
    await authRepo.logout();
    _currentUser = null;
    emit(Unauthenticated());
  }
}