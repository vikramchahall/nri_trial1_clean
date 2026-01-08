import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  // ================= CHECK AUTH =================
  void checkAuth() async {
    final user = await authRepo.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  AppUser? get currentUser => _currentUser;

  // ================= LOGIN =================
  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());

      final user =
          await authRepo.loginWithEmailPassword(email, password);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= SIMPLE SUPPORTER REGISTER =================
  Future<void> registerSimple({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      emit(AuthLoading());

      final user = await authRepo.registerSimple(
        email: email,
        password: password,
        username: username,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= REGISTER WITHOUT OTP =================
  Future<void> registerWithoutOtp({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String city,
    required String town,
    required String blockName,
    required String panchayatId,
    required String userType, // "Sarpanch" or "Supporter"
  }) async {
    try {
      emit(AuthLoading());

      final user = await authRepo.registerWithoutOtp(
        email: email,
        password: password,
        username: username,
        phoneNumber: phone,
        city: city,
        town: town,
        blockName: blockName,
        panchayatId: panchayatId,
        userType: userType,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ================= VERIFIED SARPANCH REGISTER (OTP - LEGACY) =================
  Future<void> registerSarpanchVerified({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String city,
    required String town,
    required String otp,
    dynamic webResult,
    String? vId,
  }) async {
    try {
      emit(AuthLoading());

      final user = await authRepo.registerVerifiedSarpanch(
        email: email,
        password: password,
        username: username,
        phoneNumber: phone,
        city: city,
        town: town,
        otpCode: otp,
        webResult: webResult,
        verificationId: vId,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      }
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
