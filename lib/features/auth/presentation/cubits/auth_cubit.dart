import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  // ================= TEMP CREDENTIAL MEMORY =================
  String? prefilledEmail;
  String? prefilledPassword;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  AppUser? get currentUser => _currentUser;

  // ================= CHECK AUTH (APP START) =================
  Future<void> checkAuth() async {
    final user = await authRepo.getCurrentUser();

    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  // ================= LOGIN =================
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

      // Clear stored credentials after successful login
      prefilledEmail = null;
      prefilledPassword = null;

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= REGISTER =================
  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    required String userType,
    required String phone,
    String city = '',
    String town = '',
    String block = '',
    String panchayatId = '',
  }) async {
    try {
      emit(AuthLoading());

      final user = await authRepo.registerUser(
        email: email,
        password: password,
        username: username,
        userType: userType,
        phone: phone,
        city: city,
        town: town,
        block: block,
        panchayatId: panchayatId,
      );

      if (user != null) {
        // Store for auto-fill on login
        prefilledEmail = email;
        prefilledPassword = password;

        await authRepo.sendEmailVerification();
        emit(NeedVerification(email));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= VERIFY BUTTON (IMPROVED) =================
  Future<void> checkVerificationStatus(String email) async {
    try {
      // Force Firebase to refresh token/status
      final isVerified = await authRepo.checkEmailVerified();

      if (isVerified) {
        final user = await authRepo.getCurrentUser();

        if (user != null) {
          // Success → clear prefilled creds and go home
          prefilledEmail = null;
          prefilledPassword = null;
          _currentUser = user;
          emit(Authenticated(user));
        }
      } else {
        // Still not verified → stay on verification page
        emit(NeedVerification(email));
        emit(
          AuthError(
            "Gmail link not clicked yet. Please open Gmail and click the verification link.",
          ),
        );
      }
    } catch (e) {
      emit(NeedVerification(email));
      emit(
        AuthError(
          "System busy. Please try clicking the button again in a moment.",
        ),
      );
    }
  }

  // ================= RESEND VERIFICATION =================
  Future<void> resendVerificationEmail() async {
    await authRepo.sendEmailVerification();
  }

  // ================= RESET PASSWORD =================
  Future<void> resetPassword(String email) async {
    try {
      await authRepo.sendPasswordResetEmail(email);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await authRepo.logout();
    _currentUser = null;
    emit(Unauthenticated());
  }
}
