import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';
import 'package:nri_trial1_clean/features/profile/domain/repos/profile_repo.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return ProfileUser.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    try {
      await _firestore.collection('users').doc(updatedProfile.uid).update(updatedProfile.toJson());
    } catch (e) {
      throw Exception(e);
    }
  }
}