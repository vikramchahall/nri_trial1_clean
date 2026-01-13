import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../storage/domain/storage_repo.dart';
import '../../domain/repos/profile_repo.dart';
import '../../domain/entities/profile_user.dart';
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
  // 📦 FETCH USER POSTS
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
  // ✏️ UPDATE PROFILE
  // ===============================
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    Uint8List? imageBytes,
  }) async {
    try {
      emit(ProfileLoading());

      String? imageLink;

      if (imageBytes != null) {
        imageLink = await storageRepo.uploadProfileImageMobile(
          imageBytes,
          "profile_$uid.png",
        );
      }

      final currentProfile = await profileRepo.fetchUserProfile(uid);

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWithProfile(
          bio: newBio ?? currentProfile.bio,
          profileImageUrl:
              imageLink ?? currentProfile.profileImageUrl,
        );

        await profileRepo.updateProfile(updatedProfile);

        await fetchUserProfile(uid);
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ===============================
  // 👥 FOLLOW / UNFOLLOW (CORRECT)
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentProfile =
        (state as ProfileLoaded).profileUser;

    try {
      // 1️⃣ Update backend
      await profileRepo.toggleFollow(currentUid, targetUid);

      // 2️⃣ Optimistic UI update (TARGET USER ONLY)
      final updatedFollowers =
          List<String>.from(currentProfile.followers);

      if (updatedFollowers.contains(currentUid)) {
        updatedFollowers.remove(currentUid);
      } else {
        updatedFollowers.add(currentUid);
      }

      emit(
        ProfileLoaded(
          currentProfile.copyWithProfile(
            followers: updatedFollowers,
          ),
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
