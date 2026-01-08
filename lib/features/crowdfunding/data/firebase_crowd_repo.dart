import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/comment.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/repos/crowd_repo.dart';

class FirebaseCrowdRepo implements CrowdRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===============================
  // 📌 POSTS
  // ===============================

  @override
  Future<List<CrowdPost>> fetchAllPosts() async {
    final snapshot = await _firestore
        .collection('posts')
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

  // ===============================
  // 💰 DONATION LOGIC
  // ===============================

  @override
  Future<void> donateToPost(
    String postId,
    String donorName,
    double amount,
  ) async {
    try {
      final safeDonorName =
          donorName.isNotEmpty ? donorName : "Anonymous";

      // Update raised amount
      await _firestore.collection('posts').doc(postId).update({
        'raisedAmount': FieldValue.increment(amount),
      });

      // Add donation history
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

  // ===============================
  // ❤️ LIKE / UNLIKE LOGIC
  // ===============================

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final snapshot = await postRef.get();

      final List<dynamic> likes =
          (snapshot.data()?['likes'] ?? []) as List<dynamic>;

      if (likes.contains(userId)) {
        // 👎 Unlike
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        // 👍 Like
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception("Toggle like failed: $e");
    }
  }

  // ===============================
  // 💬 COMMENT LOGIC
  // ===============================

  @override
  Future<void> addComment(String postId, Comment comment) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment.toJson());
    } catch (e) {
      throw Exception("Failed to add comment: $e");
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete comment: $e");
    }
  }
}
