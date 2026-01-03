import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';

abstract class ProfileRepo {
  // Fetch profile
  Future<ProfileUser?> fetchUserProfile(String uid);

  // Update profile
  Future<void> updateProfile(ProfileUser updatedProfile);

  // ✅ FOLLOW / UNFOLLOW (REQUIRED BY CUBIT)
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  );
}
