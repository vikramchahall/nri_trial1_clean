import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/profile_user.dart';
import '../domain/repos/profile_repo.dart';

class SupabaseProfileRepo implements ProfileRepo {
  final _supabase = Supabase.instance.client;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    final data = await _supabase.from('profiles').select().eq('id', uid).single();
    return ProfileUser.fromJson(data);
  }

  @override
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    await _supabase.from('profiles').update(updatedProfile.toJson()).eq('id', updatedProfile.uid);
  }

  @override
  Future<void> toggleFollow(String currentUid, String targetUid) async {
    final existing = await _supabase.from('follows')
        .select().eq('follower_id', currentUid).eq('following_id', targetUid).maybeSingle();

    if (existing != null) {
      await _supabase.from('follows').delete().eq('follower_id', currentUid).eq('following_id', targetUid);
    } else {
      await _supabase.from('follows').insert({'follower_id': currentUid, 'following_id': targetUid});
    }
  }
}