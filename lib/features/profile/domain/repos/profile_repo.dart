import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';

class ProfileRepo {
  final SupabaseClient _client = Supabase.instance.client;

  // ===============================
  // 📥 FETCH PROFILE
  // ===============================
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();

    return ProfileUser.fromJson(data);
  }

  // ===============================
  // ✏️ UPDATE PROFILE (BIO + IMAGE)
  // ===============================
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    await _client.from('profiles').update({
      // 🔥 MUST MATCH SUPABASE COLUMN NAMES
      'bio': updatedProfile.bio,
      'profile_image_url': updatedProfile.profileImageUrl,
    }).eq('id', updatedProfile.uid);
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    // Fetch target profile
    final target = await fetchUserProfile(targetUid);
    if (target == null) return;

    final followers = List<String>.from(target.followers);

    if (followers.contains(currentUid)) {
      followers.remove(currentUid);
    } else {
      followers.add(currentUid);
    }

    await _client
        .from('profiles')
        .update({'followers': followers})
        .eq('id', targetUid);
  }
}
