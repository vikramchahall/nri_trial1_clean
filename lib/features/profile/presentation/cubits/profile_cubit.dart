  import 'dart:typed_data';

  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

  import '../../../storage/domain/storage_repo.dart';
  import '../../domain/repos/profile_repo.dart';
  import '../../domain/entities/profile_user.dart';
  import 'profile_state.dart';
  import '../../../crowdfunding/domain/entities/crowd_post.dart';
  import '../../../auth/presentation/cubits/auth_cubit.dart';
  import '../../data/supabase_profile_repo.dart';

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
    // ✏️ UPDATE PROFILE (COMPLETE)
    // ===============================
  Future<void> updateProfile({
    required String uid,
    required AuthCubit authCubit,
    String? newBio,
    String? newUsername,
    String? newPhone,
    String? newCity,
    String? newTown,
    String? newBlock,
    String? newPanchayatId,
    Uint8List? imageBytes,
  }) async {
    try {
      // 1️⃣ Fetch current profile
      final currentProfile = await profileRepo.fetchUserProfile(uid);
      if (currentProfile == null) {
        emit(ProfileError("Profile not found"));
        return;
      }

      String? imageLink;
      int imageVersion = currentProfile.imageVersion;
      final oldImageUrl = currentProfile.profileImageUrl;

      // 2️⃣ Upload new image if provided
      if (imageBytes != null) {
        imageVersion = DateTime.now().millisecondsSinceEpoch;

        imageLink = await storageRepo.uploadProfileImageMobile(
          imageBytes,
          "profile_${uid}_$imageVersion.jpg",
        );

        // 3️⃣ Delete old image
        if (oldImageUrl.isNotEmpty &&
            imageLink != null &&
            !oldImageUrl.contains('default') &&
            profileRepo is SupabaseProfileRepo) {
          await (profileRepo as SupabaseProfileRepo)
              .deleteOldProfileImage(oldImageUrl);
        }
      }

      // 4️⃣ Build updated profile
      final updatedProfile = currentProfile.copyWithProfile(
        bio: newBio ?? currentProfile.bio,
        username: newUsername ?? currentProfile.username,
        phone: newPhone ?? currentProfile.phone,
        city: newCity ?? currentProfile.city,
        town: newTown ?? currentProfile.town,
        block: newBlock ?? currentProfile.block,
        panchayatId: newPanchayatId ?? currentProfile.panchayatId,
        profileImageUrl: imageLink ?? currentProfile.profileImageUrl,
        imageVersion: imageVersion,
      );

      // 5️⃣ Save to DB
      await profileRepo.updateProfile(updatedProfile);

      // 6️⃣ Refresh auth user
      await authCubit.refreshCurrentUser();

      // 🔥 7️⃣ REFETCH FROM DB (THIS FIXES EVERYTHING)
      final freshProfile = await profileRepo.fetchUserProfile(uid);
      if (freshProfile != null) {
        emit(ProfileLoaded(freshProfile));
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
      AuthCubit authCubit,
    ) async {
      try {
        // 1️⃣ Optimistic UI update
        if (state is ProfileLoaded) {
          final currentProfile = (state as ProfileLoaded).profileUser;
          final isFollowing = currentProfile.followers.contains(currentUid);
          
          final updatedFollowers = List<String>.from(currentProfile.followers);
          if (isFollowing) {
            updatedFollowers.remove(currentUid);
          } else {
            updatedFollowers.add(currentUid);
          }
          
          emit(ProfileLoaded(
            currentProfile.copyWith(followers: updatedFollowers),
          ));
        }

        // 2️⃣ Update database
        await profileRepo.toggleFollow(currentUid, targetUid);

        // 3️⃣ Refresh auth user (updates following list)
        await authCubit.refreshCurrentUser();

        // 4️⃣ Refresh profile (get accurate count)
        await fetchUserProfile(targetUid);
      } catch (e) {
        emit(ProfileError(e.toString()));
        await fetchUserProfile(targetUid);
      }
    }
  }