import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/comment.dart';

abstract class CrowdRepo {
  Future<List<CrowdPost>> fetchAllPosts();
  Future<void> createPost(CrowdPost post);
  Future<void> deletePost(String postId);
  Future<void> donateToPost(String postId, String donorName, double amount);

  // COMMENTS
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
}
