import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/crowd_post.dart';
import '../domain/entities/comment.dart';
import '../domain/repos/crowd_repo.dart';
import 'package:flutter/foundation.dart';

class SupabaseCrowdRepo implements CrowdRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 📌 POSTS
  // ===============================
  @override
  Future<List<CrowdPost>> fetchAllPosts() async {
    final response = await _supabase
        .from('posts')
        .select('*, likes(user_id)')
        .order('timestamp', ascending: false);

    return (response as List).map((json) {
      final likesList = (json['likes'] as List?)
              ?.map((l) => l['user_id'].toString())
              .toList() ??
          [];
      return CrowdPost.fromJson(
        {...json, 'likes': likesList},
        json['id'].toString(),
      );
    }).toList();
  }

  @override
  Future<List<CrowdPost>> fetchPostsByUserId(String uid) async {
    final response = await _supabase
        .from('posts')
        .select('*, likes(user_id)')
        .eq('user_id', uid)
        .order('timestamp', ascending: false);

    return (response as List).map((json) {
      final likesList = (json['likes'] as List?)
              ?.map((l) => l['user_id'].toString())
              .toList() ??
          [];
      return CrowdPost.fromJson(
        {...json, 'likes': likesList},
        json['id'].toString(),
      );
    }).toList();
  }

  @override
  Future<void> createPost(CrowdPost post) async {
    try {
      await _supabase.from('posts').insert({
        'user_id': post.userId,
        'user_name': post.userName,
        'text': post.text,
        'image_url': post.imageUrl,
        'target_amount': post.targetAmount,
        'raised_amount': post.raisedAmount,
        'likes': [],
        'comment_count': 0,
        'phone_number': post.phoneNumber,
      });
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
      throw Exception("Failed to save post: $e");
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      debugPrint("🔍 Starting post deletion for ID: $postId");

      final postData = await _supabase
          .from('posts')
          .select('image_url')
          .eq('id', postId)
          .maybeSingle();

      if (postData != null && postData['image_url'] != null) {
        final imageUrl = postData['image_url'] as String;
        if (imageUrl.isNotEmpty) await _deletePostImage(imageUrl);
      }

      try {
        await _supabase.from('comments').delete().eq('post_id', postId);
        debugPrint("✅ Comments deleted");
      } catch (e) {
        debugPrint("⚠️ No comments to delete");
      }

      try {
        await _supabase.from('donations').delete().eq('post_id', postId);
        debugPrint("✅ Donations deleted");
      } catch (e) {
        debugPrint("⚠️ No donations to delete");
      }

      await _supabase.from('posts').delete().eq('id', postId);
      debugPrint("✅ Post deleted successfully");
    } catch (e) {
      debugPrint("❌ Error deleting post: $e");
      rethrow;
    }
  }

  Future<void> _deletePostImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments
          .skipWhile((segment) => segment != 'post_images')
          .skip(1)
          .join('/');
      if (path.isNotEmpty) {
        await _supabase.storage.from('post_images').remove([path]);
        debugPrint("✅ Post image deleted from storage");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to delete post image: $e");
    }
  }

  // ===============================
  // 💰 DONATION
  // ===============================
  @override
  Future<void> donateToPost(String postId, String donorName, double amount) async {
    await _supabase.from('posts').update({'raised_amount': amount}).eq('id', postId);
    await _supabase.from('donations').insert({
      'post_id': postId,
      'donor_name': donorName,
      'amount': amount,
    });
  }

  // ===============================
  // ❤️ LIKE / UNLIKE
  // ===============================
  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final existing = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await _supabase.from('likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      debugPrint("❌ toggleLikePost error: $e");
      rethrow;
    }
  }

  // ===============================
  // 💬 COMMENTS
  // ===============================
  @override
  Future<void> addComment(String postId, Comment comment) async {
    // ✅ Only insert — NO rpc increment (cubit handles local count)
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
    // ✅ Only delete — NO rpc decrement (cubit handles local count)
    await _supabase.from('comments').delete().eq('id', commentId);
  }

  // ✅ NEW — fetch real count from DB
  @override
  Future<int> getCommentCount(String postId) async {
    final result = await _supabase
        .from('comments')
        .select('id')
        .eq('post_id', postId);
    return (result as List).length;
  }

  // ===============================
  // 📢 OFFICIAL UPDATES
  // ===============================
  @override
  Future<List<Map<String, dynamic>>> fetchOfficialUpdates() async {
    return await _supabase
        .from('official_updates')
        .select()
        .order('timestamp', ascending: false);
  }

  @override
  Future<void> postOfficialUpdate(
      String title, String message, String mediaUrl, String type) async {
    await _supabase.from('official_updates').insert({
      'title': title,
      'message': message,
      'media_url': mediaUrl,
      'media_type': type,
    });
  }
}