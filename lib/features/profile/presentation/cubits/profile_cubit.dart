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
  // ✅ FIX: FETCH USER POSTS (GRID)
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

      String? newImageUrl;

      // Upload image if provided
      if (imageBytes != null) {
        newImageUrl = await storageRepo.uploadProfileImageMobile(
          imageBytes,
          "profile_$uid.png",
        );
      }

      final currentProfile = await profileRepo.fetchUserProfile(uid);

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          newBio: newBio ?? currentProfile.bio,
          newProfileImageUrl:
              newImageUrl ?? currentProfile.profileImageUrl,
        );

        await profileRepo.updateProfile(updatedProfile);
        await fetchUserProfile(uid);
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    try {
      await profileRepo.toggleFollow(currentUid, targetUid);
      fetchUserProfile(targetUid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
