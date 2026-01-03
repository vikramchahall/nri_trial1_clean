import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/profile/domain/repos/profile_repo.dart';
import 'package:nri_trial1_clean/features/storage/domain/storage_repo.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo profileRepo;
  final StorageRepo storageRepo;

  ProfileCubit({
    required this.profileRepo,
    required this.storageRepo,
  }) : super(ProfileInitial());

  // ===============================
  // Fetch user profile
  // ===============================
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

  // ===============================
  // ✅ UPDATE PROFILE (BIO + IMAGE)
  // ===============================
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    Uint8List? imageBytes,
  }) async {
    try {
      emit(ProfileLoading());

      String? newImageUrl;

      // 1️⃣ Upload image to Supabase if picked
      if (imageBytes != null) {
        newImageUrl = await storageRepo.uploadProfileImageMobile(
          imageBytes,
          "profile_$uid.png", // ✅ IMPORTANT: extension
        );
      }

      // 2️⃣ Fetch current profile
      final currentProfile = await profileRepo.fetchUserProfile(uid);

      if (currentProfile != null) {
        // 3️⃣ Merge updated fields
        final updatedProfile = currentProfile.copyWith(
          newBio: newBio ?? currentProfile.bio,
          newProfileImageUrl:
              newImageUrl ?? currentProfile.profileImageUrl,
        );

        // 4️⃣ Save to Firestore
        await profileRepo.updateProfile(updatedProfile);

        // 5️⃣ Re-fetch from DB (single source of truth)
        await fetchUserProfile(uid);
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ===============================
  // FOLLOW / UNFOLLOW
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    try {
      await profileRepo.toggleFollow(currentUid, targetUid);

      // 🔄 Refresh target profile
      fetchUserProfile(targetUid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
