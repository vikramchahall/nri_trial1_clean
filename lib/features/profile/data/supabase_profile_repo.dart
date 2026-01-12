import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/profile_user.dart';
import '../domain/repos/profile_repo.dart';

class SupabaseProfileRepo implements ProfileRepo {
  final _supabase = Supabase.instance.client;

  // ===============================
  // 👤 FETCH USER PROFILE + FOLLOWER / FOLLOWING COUNT (FIXED)
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
  // ✏️ UPDATE PROFILE (PHASE 2 FIX)
  // ===============================
  @override
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'bio': updatedProfile.bio,
            'profile_image_url': updatedProfile.profileImageUrl,
            'username': updatedProfile.username,
          })
          // ✅ ensure only THIS user's row is updated
          .eq('id', updatedProfile.uid);
    } catch (e) {
      throw Exception("Update failed: $e");
    }
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW (SQL VERSION)
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
