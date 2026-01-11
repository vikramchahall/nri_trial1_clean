import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

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
  // LOGIN
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
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // REGISTER (WITH BLOCK + PANCHAYAT ID)
  // ==================================================
  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    required String userType, // Pind / User / DC
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

      // 🔑 Supabase ALWAYS needs email confirmation
      emit(NeedVerification(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================================================
  // EMAIL VERIFICATION CHECK (POLLING)
  // ==================================================
  Future<void> checkStatus(String email) async {
    try {
      final isVerified = await authRepo.checkEmailVerified();

      if (isVerified) {
        final user = await authRepo.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(NeedVerification(email));
        emit(
          AuthError(
            "Please open Gmail and click the verification link.",
          ),
        );
      }
    } catch (_) {
      emit(NeedVerification(email));
      emit(AuthError("System busy. Please try again."));
    }
  }

  // ✅ ALIAS (keeps older UI safe)
  Future<void> checkVerificationStatus(String email) {
    return checkStatus(email);
  }

  // ==================================================
  // FORGOT PASSWORD
  // ==================================================
  Future<void> forgotPassword(String email) async {
    try {
      await authRepo.sendPasswordResetEmail(email);
      emit(PasswordResetSent(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ✅ ALIAS (LoginPage compatibility)
  Future<void> resetPassword(String email) {
    return forgotPassword(email);
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
