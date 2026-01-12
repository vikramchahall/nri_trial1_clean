import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/profile_user.dart';
import '../domain/repos/profile_repo.dart';

class SupabaseProfileRepo implements ProfileRepo {
  final _supabase = Supabase.instance.client;

  // ===============================
  // 👤 FETCH USER PROFILE + FOLLOWER COUNT
  // ===============================
  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      // 🔗 Join profiles with follows table (followers)
      final response = await _supabase
          .from('profiles')
          .select('*, follows!following_id(follower_id)')
          .eq('id', uid)
          .single();

      // 📊 Extract follower IDs
      final List followersData = response['follows'] ?? [];
      final List<String> followerIds = followersData
          .map((f) => f['follower_id'].toString())
          .toList();

      // 🧠 Inject followers list into profile model
      return ProfileUser.fromJson({
        ...response,
        'followers': followerIds,
      });
    } catch (e) {
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
          // ✅ CRITICAL: ensure only THIS user's row is updated
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
      // 1️⃣ Check if follow relationship already exists
      final existingFollow = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUid)
          .eq('following_id', targetUid)
          .maybeSingle();

      if (existingFollow != null) {
        // 2️⃣ UNFOLLOW → delete row
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUid)
            .eq('following_id', targetUid);
      } else {
        // 3️⃣ FOLLOW → insert row
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
