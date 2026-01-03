import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= LOGIN =================
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;

      return AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: data['username'] ?? '',
        userType: data['userType'] ?? 'Supporter',
        phoneNumber: data['phoneNumber'] ?? '',
        city: data['city'] ?? '',
        town: data['town'] ?? '',
        isPhoneVerified: data['isPhoneVerified'] ?? false,
        isAdmin: data['isAdmin'] ?? false,
        followers: List<String>.from(data['followers'] ?? []),
        following: List<String>.from(data['following'] ?? []),
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ================= SEND OTP =================
  @override
  Future<dynamic> sendOtp(String mobile) async {
    final String fullNumber = "+91$mobile";

    if (kIsWeb) {
      // WEB → Recaptcha flow
      return await _auth.signInWithPhoneNumber(fullNumber);
    } else {
      // ANDROID / iOS → Native OTP
      final completer = Completer<String>();

      await _auth.verifyPhoneNumber(
        phoneNumber: fullNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(
            e.message ?? "OTP verification failed",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return completer.future;
    }
  }

  // ================= VERIFIED SARPANCH =================
  @override
  Future<AppUser?> registerVerifiedSarpanch({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String city,
    required String town,
    required String otpCode,
    dynamic webResult,
    String? verificationId,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      // USERNAME CHECK
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw Exception(
          "The username '$username' is already taken.",
        );
      }

      // OTP VERIFICATION
      if (kIsWeb) {
        await webResult.confirm(otpCode);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: otpCode,
        );
        await _auth.currentUser?.linkWithCredential(credential);
      }

      // CREATE ACCOUNT
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: normalizedUsername,
        userType: 'Sarpanch',
        phoneNumber: phoneNumber,
        city: city,
        town: town,
        isPhoneVerified: true,
        isAdmin: false,
        followers: [],
        following: [],
      );

      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      return user;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ================= SIMPLE SUPPORTER =================
  @override
  Future<AppUser?> registerSimple({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw Exception(
          "The username '$username' is already taken.",
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: normalizedUsername,
        userType: 'Supporter',
        isAdmin: false,
        followers: [],
        following: [],
      );

      await _firestore.collection('users').doc(user.uid).set(user.toJson());
      return user;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ================= LOGOUT =================
  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ================= CURRENT USER =================
  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) return null;

    final data = userDoc.data() as Map<String, dynamic>;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      username: data['username'] ?? '',
      userType: data['userType'] ?? 'Supporter',
      phoneNumber: data['phoneNumber'] ?? '',
      city: data['city'] ?? '',
      town: data['town'] ?? '',
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
    );
  }
}
