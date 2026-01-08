import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/comment.dart';

abstract class CrowdRepo {
  // 📥 POSTS
  Future<List<CrowdPost>> fetchAllPosts();
  Future<void> createPost(CrowdPost post);
  Future<void> deletePost(String postId);

  // 💰 DONATIONS
  Future<void> donateToPost(
    String postId,
    String donorName,
    double amount,
  );

  // ❤️ LIKE / UNLIKE  ✅ ADDED
  Future<void> toggleLikePost(String postId, String userId);

  // 💬 COMMENTS
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
}
