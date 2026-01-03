import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/repos/crowd_repo.dart';

class FirebaseCrowdRepo implements CrowdRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CrowdPost>> fetchAllPosts() async {
    final snapshot = await _firestore
        .collection('posts') // ✅ CONSISTENT COLLECTION NAME
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CrowdPost.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> createPost(CrowdPost post) async {
    await _firestore.collection('posts').add(post.toJson());
  }

  @override
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  @override
  Future<void> donateToPost(
    String postId,
    String donorName,
    double amount,
  ) async {
    try {
      // ✅ SAFETY: avoid null donor name
      final safeDonorName =
          donorName.isNotEmpty ? donorName : "Anonymous";

      // 1. Update the raised amount
      await _firestore.collection('posts').doc(postId).update({
        'raisedAmount': FieldValue.increment(amount),
      });

      // 2. Add donation history
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('donations')
          .add({
        'donorName': safeDonorName,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Donation failed: $e");
    }
  }
}
