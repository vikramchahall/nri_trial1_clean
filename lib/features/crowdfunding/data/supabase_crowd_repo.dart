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
    try {
      // These keys MUST match the SQL column names exactly
      await _supabase.from('posts').insert({
        'user_id': post.userId,      // NOT uId or userId
        'user_name': post.userName,  // NOT uName or userName
        'text': post.text,
        'image_url': post.imageUrl,
        'target_amount': post.targetAmount,
        'raised_amount': post.raisedAmount,
        'likes': [],                 // Matches the JSONB column
      });
    } catch (e) {
      // This will print the exact reason if it fails again
      debugPrint("UPLOAD ERROR: $e");
      throw Exception("Failed to save post: $e");
    }
  }


 @override
Future<void> deletePost(String postId) async {
  try {
    debugPrint("🔍 Starting post deletion for ID: $postId");

    // 1️⃣ First, fetch the post to get the image URL
    final postData = await _supabase
        .from('posts')
        .select('image_url')
        .eq('id', postId)
        .maybeSingle();

    // 2️⃣ Delete image from storage if exists
    if (postData != null && postData['image_url'] != null) {
      final imageUrl = postData['image_url'] as String;
      
      if (imageUrl.isNotEmpty) {
        await _deletePostImage(imageUrl);
      }
    }

    // 3️⃣ Delete comments associated with this post (if table exists)
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('post_id', postId);
      debugPrint("✅ Comments deleted");
    } catch (e) {
      debugPrint("⚠️ No comments to delete or comments table doesn't exist");
    }

    // 4️⃣ Delete donations (skip if table doesn't exist yet)
    try {
      await _supabase
          .from('donations')
          .delete()
          .eq('post_id', postId);
      debugPrint("✅ Donations deleted");
    } catch (e) {
      debugPrint("⚠️ No donations to delete or donations table doesn't exist");
    }

    // 5️⃣ Delete the post from database
    await _supabase
        .from('posts')
        .delete()
        .eq('id', postId);

    debugPrint("✅ Post deleted successfully");

  } catch (e) {
    debugPrint("❌ Error deleting post: $e");
    rethrow;
  }
}

// Helper method to delete post image from storage
Future<void> _deletePostImage(String imageUrl) async {
  try {
    final uri = Uri.parse(imageUrl);
    
    // Extract path after 'post_images'
    // Example URL: https://xxx.supabase.co/storage/v1/object/public/post_images/gaganjeet/1768719502280.jpg
    // Extracts: gaganjeet/1768719502280.jpg
    final path = uri.pathSegments
        .skipWhile((segment) => segment != 'post_images')
        .skip(1)  // Skip 'post_images' itself
        .join('/');  // Joins username/filename

    debugPrint("🖼️ Deleting post image at path: $path");

    if (path.isNotEmpty) {
      await _supabase.storage
          .from('post_images')
          .remove([path]);
      
      debugPrint("✅ Post image deleted from storage");
    }
  } catch (e) {
    debugPrint("⚠️ Failed to delete post image: $e");
    // Don't throw - this shouldn't stop the post deletion
  }
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
  @override
Future<List<Map<String, dynamic>>> fetchOfficialUpdates() async {
  return await _supabase.from('official_updates').select().order('timestamp', ascending: false);
}

@override
Future<void> postOfficialUpdate(String title, String message, String mediaUrl, String type) async {
  await _supabase.from('official_updates').insert({
    'title': title,
    'message': message,
    'media_url': mediaUrl,
    'media_type': type,
  });
}
}
