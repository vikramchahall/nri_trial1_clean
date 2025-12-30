import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/profile/domain/repos/profile_repo.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo profileRepo;

  ProfileCubit({required this.profileRepo}) : super(ProfileInitial());

  // Fetch user profile
  Future<void> fetchUserProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError("User not found"));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // Update bio
  Future<void> updateBio(String uid, String newBio) async {
    try {
      final currentUser = await profileRepo.fetchUserProfile(uid);
      if (currentUser != null) {
        final updatedProfile = currentUser.copyWith(newBio: newBio);
        await profileRepo.updateProfile(updatedProfile);
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError("Error updating bio"));
    }
  }
}