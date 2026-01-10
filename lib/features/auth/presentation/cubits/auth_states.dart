import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState { final AppUser user; Authenticated(this.user); }
class Unauthenticated extends AuthState {}
class AuthError extends AuthState { final String message; AuthError(this.message); }  
class NeedVerification extends AuthState { final String email; NeedVerification(this.email); }