import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nri_trial1_clean/features/auth/domain/entities/app_user.dart';
import 'package:nri_trial1_clean/features/auth/domain/repos/auth_repo.dart';


class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 @override
Future<AppUser?> loginWithEmailPassword(
    String email,
    String password,
) async {
  final cred = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );

  final uid = cred.user!.uid;

  final emailDoc =
      await _firestore.collection('user_emails').doc(email).get();

  if (!emailDoc.exists) {
    throw Exception("User role not found");
  }

  final data = emailDoc.data()!;

  return AppUser(
    uid: uid,
    email: email,
    isAdmin: data['isAdmin'] ?? false,
  );
}

@override
Future<AppUser?> registerWithEmailPassword(
    String email,
    String password,
) async {
  final cred = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final uid = cred.user!.uid;

  // Identity only
  await _firestore.collection('users').doc(uid).set({
    'uid': uid,
    'email': email,
  });

  // ROLE SOURCE (YOU EDIT THIS)
  await _firestore.collection('user_emails').doc(email).set({
    'uid': uid,
    'isAdmin': false,
  });

  return AppUser(uid: uid, email: email, isAdmin: false);
}

  @override
  Future<void> logout() async => await _auth.signOut();

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    
    // Fetch role from Firestore
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    return AppUser(
      uid: firebaseUser.uid, 
      email: firebaseUser.email!,
      isAdmin: userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['isAdmin'] ?? false : false,
    );
  }
}