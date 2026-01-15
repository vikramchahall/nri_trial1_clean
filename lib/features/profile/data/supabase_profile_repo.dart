import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/profile_user.dart';
import '../domain/repos/profile_repo.dart';

class SupabaseProfileRepo implements ProfileRepo {
  final _supabase = Supabase.instance.client;

  // ===============================
  // 👤 FETCH USER PROFILE + FOLLOWER / FOLLOWING COUNT
  // ===============================
  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      // 🔥 Fetch profile + followers + following in ONE query
      final response = await _supabase
          .from('profiles')
          .select(
            '*, '
            'follows!following_id(follower_id), '
            'following:follows!follower_id(following_id)',
          )
          .eq('id', uid)
          .single();

      // 📊 Extract followers
      final List followersRaw = response['follows'] ?? [];
      final List<String> followerIds = followersRaw
          .map((f) => f['follower_id'].toString())
          .toList();

      // 📊 Extract following
      final List followingRaw = response['following'] ?? [];
      final List<String> followingIds = followingRaw
          .map((f) => f['following_id'].toString())
          .toList();

      // 🧠 Inject lists into ProfileUser
      return ProfileUser.fromJson({
        ...response,
        'followers': followerIds,
        'following': followingIds,
      });
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
      return null;
    }
  }

  // ===============================
  // ✏️ UPDATE PROFILE (WITH IMAGE VERSION)
  // ===============================
@override
Future<void> updateProfile(ProfileUser updatedProfile) async {
  try {
    await _supabase.from('profiles').update({
      'username': updatedProfile.username.toLowerCase().trim(),
      'bio': updatedProfile.bio,
      'phone': updatedProfile.phone,
      'city': updatedProfile.city,
      'town': updatedProfile.town,
      'block_name': updatedProfile.block,
      'panchayat_id': updatedProfile.panchayatId,
      'profile_image_url': updatedProfile.profileImageUrl,
      'image_version': updatedProfile.imageVersion,
    }).eq('id', updatedProfile.uid);

    print('✅ Profile updated in database');
    
  } on PostgrestException catch (e) {
    print('❌ Postgres Error: ${e.code} ${e.message}');
    if (e.code == '23505') {
      throw Exception('Username already taken');
    }
    rethrow;
  } catch (e) {
    print('❌ Update Error: $e');
    rethrow;
  }
}


  // ===============================
  // 🗑️ DELETE OLD PROFILE IMAGE FROM STORAGE
  // ===============================
  Future<void> deleteOldProfileImage(String imageUrl) async {
    try {
      // Extract filename from URL
      // Example URL: https://xxx.supabase.co/storage/v1/object/public/profile_images/profile_123_456.jpg?v=789
      final uri = Uri.parse(imageUrl);
      final path = uri.path;
      
      // Get filename after 'profile_images/'
      final parts = path.split('/');
      if (parts.length >= 2) {
        final fileName = parts.last;
        
        await _supabase.storage
            .from('profile_images')
            .remove([fileName]);
        
        debugPrint("✅ Deleted old image: $fileName");
      }
    } catch (e) {
      debugPrint("⚠️ Failed to delete old image: $e");
      // Don't throw - this shouldn't stop the update
    }
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW
  // ===============================
  @override
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    try {
      final existingFollow = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUid)
          .eq('following_id', targetUid)
          .maybeSingle();

      if (existingFollow != null) {
        // UNFOLLOW
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUid)
            .eq('following_id', targetUid);
      } else {
        // FOLLOW
        await _supabase.from('follows').insert({
          'follower_id': currentUid,
          'following_id': targetUid,
        });
      }
    } catch (e) {
      throw Exception("Follow/Unfollow failed: $e");
    }
  }
}