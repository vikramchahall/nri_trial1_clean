import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../storage/domain/storage_repo.dart';
import '../../domain/repos/profile_repo.dart';
import 'profile_state.dart';
import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

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
  // 👥 FOLLOW / UNFOLLOW (FINAL, CORRECT)
  // ===============================
  Future<void> toggleFollow(
    String currentUid,
    String targetUid,
    AuthCubit authCubit,
  ) async {
    try {
      // 1️⃣ Update follows table
      await profileRepo.toggleFollow(currentUid, targetUid);

      // 2️⃣ Refresh TARGET profile
      await fetchUserProfile(targetUid);

      // 3️⃣ Refresh AUTH (following list)
      await authCubit.refreshCurrentUser();

      // 4️⃣ 🔥 Refresh MY PROFILE (fixes stale counts)
      await fetchUserProfile(currentUid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
