import '../entities/crowd_post.dart';
import '../entities/comment.dart';

abstract class CrowdRepo {
  Future<List<CrowdPost>> fetchAllPosts();
  Future<void> createPost(CrowdPost post);
  Future<void> deletePost(String postId);
  Future<void> toggleLikePost(String postId, String userId);
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> donateToPost(String postId, String donorName, double amount); // Ensure this is here
  Future<List<CrowdPost>> fetchPostsByUserId(String uid);
}