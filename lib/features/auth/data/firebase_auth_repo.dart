import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= EMAIL VERIFICATION =================
  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // THIS LINE IS MANDATORY
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }
  // ================= LOGIN =================
  @override
  Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // 🔥 FORCE REFRESH
      await firebaseUser.reload();
      final refreshedUser = _auth.currentUser;

      // 🚫 BLOCK IF EMAIL NOT VERIFIED
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await refreshedUser?.sendEmailVerification();
        throw Exception(
          "Email not verified. Please check your inbox or spam folder.",
        );
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return null;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      return AppUser(
        uid: refreshedUser.uid,
        email: refreshedUser.email!,
        username: data['username'] ?? '',
        userType: data['userType'] ?? 'Supporter',
        phoneNumber: data['phoneNumber'] ?? '',
        city: data['city'] ?? '',
        town: data['town'] ?? '',
        blockName: data['blockName'] ?? '',
        panchayatId: data['panchayatId'] ?? '',
        isAdmin: data['isAdmin'] ?? false,
        followers: List<String>.from(data['followers'] ?? []),
        following: List<String>.from(data['following'] ?? []),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= PASSWORD RESET =================
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Exception("Reset error: ${e.toString()}");
    }
  }

  // ================= REGISTER =================
  @override
  Future<AppUser?> registerUser({
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
      final normalizedEmail = email.trim();
      final normalizedUsername = username.trim().toLowerCase();

      // 🔍 CHECK UNIQUE USERNAME
      final nameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (nameCheck.docs.isNotEmpty) {
        throw Exception("Username already taken");
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      // 📧 SEND VERIFICATION EMAIL
      await userCredential.user!.sendEmailVerification();

      final user = AppUser(
        uid: userCredential.user!.uid,
        email: normalizedEmail,
        username: normalizedUsername,
        userType: userType,
        phoneNumber: phone,
        city: city,
        town: town,
        blockName: block,
        panchayatId: panchayatId,
        isAdmin: false,
        followers: [],
        following: [],
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());

      // 🔥 SIGN OUT AFTER REGISTER
      await _auth.signOut();

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= CURRENT USER =================
  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // 🔥 FORCE REFRESH
    await firebaseUser.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null || !refreshedUser.emailVerified) {
      await _auth.signOut();
      return null;
    }

    final userDoc =
        await _firestore.collection('users').doc(refreshedUser.uid).get();

    if (!userDoc.exists) {
      await _auth.signOut();
      return null;
    }

    final data = userDoc.data() as Map<String, dynamic>;

    return AppUser(
      uid: refreshedUser.uid,
      email: refreshedUser.email!,
      username: data['username'] ?? '',
      userType: data['userType'] ?? 'Supporter',
      phoneNumber: data['phoneNumber'] ?? '',
      city: data['city'] ?? '',
      town: data['town'] ?? '',
      blockName: data['blockName'] ?? '',
      panchayatId: data['panchayatId'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
    );
  }

  // ================= LOGOUT =================
  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}
