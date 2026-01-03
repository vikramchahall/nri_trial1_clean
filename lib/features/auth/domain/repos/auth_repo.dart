import '../entities/app_user.dart';

abstract class AuthRepo {
  // ================= LOGIN =================
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  );

  // ================= OTP (PLATFORM AWARE) =================
  /// Web  → returns ConfirmationResult
  /// Mobile → returns verificationId (String)
  Future<dynamic> sendOtp(String mobile);

  // ================= VERIFIED SARPANCH REGISTRATION =================
  Future<AppUser?> registerVerifiedSarpanch({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String city,
    required String town,
    required String otpCode,

    /// Web-only
    dynamic webResult,

    /// Android / iOS-only
    String? verificationId,
  });

  // ================= SIMPLE REGISTRATION (SUPPORTER) =================
  Future<AppUser?> registerSimple({
    required String email,
    required String password,
    required String username,
  });

  // ================= SESSION =================
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
}
