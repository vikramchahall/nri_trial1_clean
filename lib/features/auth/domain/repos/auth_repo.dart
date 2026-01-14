import '../entities/app_user.dart';

abstract class AuthRepo {
  // ================= LOGIN =================
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  );

  // ================= REGISTER =================
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String username,
    required String phone, // ✅ ADD
    required String userType,
    String city,
    String town,
    String block,
    String panchayatId,
  });

  // ================= CURRENT USER =================
  Future<AppUser?> getCurrentUser();

  // ================= PASSWORD RESET =================
  Future<void> sendPasswordResetEmail(String email);

  // 🔐 OTP verification + password reset (THIS WAS MISSING)
  Future<void> verifyOtpAndSetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  // 🔐 Update password for logged-in user
  Future<void> updatePassword(String newPassword);

  // ================= EMAIL VERIFICATION =================
  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerified();

  Future<void> deleteAccount(String password);

  // ================= LOGOUT =================
  Future<void> logout();
}
