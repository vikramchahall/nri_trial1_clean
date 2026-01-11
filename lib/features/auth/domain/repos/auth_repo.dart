import '../entities/app_user.dart';

abstract class AuthRepo {
  // LOGIN
  Future<AppUser?> loginWithEmailPassword(String email, String password);

  // REGISTER
  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String username,
    required String userType,

    String city,
    String town,
    String block,
    String panchayatId,
  });

  // EMAIL VERIFICATION (NEW)
  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerified();

  // CURRENT USER
  Future<AppUser?> getCurrentUser();

  // PASSWORD RESET
  Future<void> sendPasswordResetEmail(String email);

  // LOGOUT
  Future<void> logout();
}
