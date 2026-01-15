import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

// ===============================
// BASE STATES
// ===============================
class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ===============================
// AUTH FLOW STATES
// ===============================

// After registration → user must verify email
class NeedVerification extends AuthState {
  final String email;
  final String? password; // Add this
  
   NeedVerification({
    required this.email,
    this.password, // Add this
  });
}


// After forgot password → OTP sent
class PasswordResetSent extends AuthState {
  final String email;
  PasswordResetSent(this.email);
}

// 🔐 ENTER OTP + NEW PASSWORD SCREEN (FIXED & CORRECT)
class ResetPasswordOtpMode extends AuthState {
  final String email;
  ResetPasswordOtpMode(this.email);
}

// 🔐 PASSWORD RECOVERY MODE (legacy / optional)
class PasswordRecoveryMode extends AuthState {}
