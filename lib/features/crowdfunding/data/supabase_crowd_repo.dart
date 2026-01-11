import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/crowd_post.dart';
import '../domain/entities/comment.dart';
import '../domain/repos/crowd_repo.dart';

class SupabaseCrowdRepo implements CrowdRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 📌 POSTS
  // ===============================
  @override
  Future<List<CrowdPost>> fetchAllPosts() async {
    final response = await _supabase
        .from('posts')
        .select()
        .order('timestamp', ascending: false);

    return (response as List)
        .map(
          (json) => CrowdPost.fromJson(
            json as Map<String, dynamic>,
            json['id'].toString(),
          ),
        )
        .toList();
  }

  @override
  Future<List<CrowdPost>> fetchPostsByUserId(String uid) async {
    final response = await _supabase
        .from('posts')
        .select()
        .eq('user_id', uid)
        .order('timestamp', ascending: false);

    return (response as List)
        .map(
          (json) => CrowdPost.fromJson(
            json as Map<String, dynamic>,
            json['id'].toString(),
          ),  
        )
        .toList();
  }

  @override
  Future<void> createPost(CrowdPost post) async {
    await _supabase.from('posts').insert(post.toJson());
  }

  @override
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // ===============================
  // 💰 DONATION (✅ FIXED)
  // ===============================
  @override
  Future<void> donateToPost(
    String postId,
    String donorName,
    double amount,
  ) async {
    // 1️⃣ Increment raised_amount
    await _supabase
        .from('posts')
        .update({
          'raised_amount': amount,
        })
        .eq('id', postId);

    // 2️⃣ Store donation history
    await _supabase.from('donations').insert({
      'post_id': postId,
      'donor_name': donorName,
      'amount': amount,
    });
  }

  // ===============================
  // ❤️ LIKE / UNLIKE (stub for now)
  // ===============================
  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    // Will be implemented later
  }

  // ===============================
  // 💬 COMMENTS
  // ===============================
  @override
  Future<void> addComment(String postId, Comment comment) async {
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': comment.userId,
      'user_name': comment.userName,
      'text': comment.text,
      'timestamp': comment.timestamp.toIso8601String(),
    });
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
  }
}
