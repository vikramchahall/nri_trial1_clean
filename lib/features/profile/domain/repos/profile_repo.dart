import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';


abstract class ProfileRepo {
  Future<ProfileUser?> fetchUserProfile(String uid);
  Future<void> updateProfile(ProfileUser updatedProfile);
}