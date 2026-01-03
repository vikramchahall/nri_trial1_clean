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
      await _firestore
          .collection('users')
          .doc(updatedProfile.uid)
          .update(updatedProfile.toJson());
    } catch (e) {
      throw Exception(e);
    }
  }

  // ===============================
  // ✅ FOLLOW / UNFOLLOW LOGIC (STEP 2)
  // ===============================
  @override // ADD THIS LINE HERE
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    try {
      final currentUserDoc =
          _firestore.collection('users').doc(currentUid);
      final targetUserDoc =
          _firestore.collection('users').doc(targetUid);

      final doc = await currentUserDoc.get();
      final List following = doc['following'] ?? [];

      if (following.contains(targetUid)) {
        // 🔁 UNFOLLOW
        await currentUserDoc.update({
          'following': FieldValue.arrayRemove([targetUid]),
        });
        await targetUserDoc.update({
          'followers': FieldValue.arrayRemove([currentUid]),
        });
      } else {
        // ➕ FOLLOW
        await currentUserDoc.update({
          'following': FieldValue.arrayUnion([targetUid]),
        });
        await targetUserDoc.update({
          'followers': FieldValue.arrayUnion([currentUid]),
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
