import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../storage/domain/storage_repo.dart';
import '../../domain/repos/profile_repo.dart';
import 'profile_state.dart';
import '../../../crowdfunding/domain/entities/crowd_post.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo profileRepo;
  final StorageRepo storageRepo;

  ProfileCubit({
    required this.profileRepo,
    required this.storageRepo,
  }) : super(ProfileInitial());

  // ===============================
  // 📥 FETCH USER PROFILE
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
  // 📦 FETCH USER POSTS (GRID)
  // ===============================
  Future<List<CrowdPost>> fetchUserPosts(String uid) async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('user_id', uid)
          .order('timestamp', ascending: false);

      return (response as List)
          .map(
            (json) => CrowdPost.fromJson(
              json,
              json['id'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ===============================
  // ✏️ UPDATE PROFILE (BIO + IMAGE)
  // ===============================
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    Uint8List? imageBytes,
  }) async {
    try {
      emit(ProfileLoading());

      String? imageLink;

      // 📤 1️⃣ Upload image if provided
      if (imageBytes != null) {
        imageLink = await storageRepo.uploadProfileImageMobile(
          imageBytes,
          "profile_$uid.png",
        );
      }

      // 📥 2️⃣ Fetch current profile
      final currentProfile = await profileRepo.fetchUserProfile(uid);

      if (currentProfile != null) {
        // ✍️ 3️⃣ Create updated profile with NEW image link
        final updatedProfile = currentProfile.copyWith(
          newBio: newBio ?? currentProfile.bio,
          // If user didn’t pick a new image, keep the old one
          newProfileImageUrl:
              imageLink ?? currentProfile.profileImageUrl,
        );

        // 💾 4️⃣ Update profile in Supabase
        await profileRepo.updateProfile(updatedProfile);

        // 🔁 5️⃣ Force refresh UI with latest data
        await fetchUserProfile(uid);
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW (PHASE 1 FIX)
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    try {
      // 1️⃣ Perform DB change
      await profileRepo.toggleFollow(currentUid, targetUid);

      // 2️⃣ THE FIX: Immediately re-fetch profile
      // Forces Cubit to emit fresh ProfileLoaded state
      await fetchUserProfile(targetUid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
