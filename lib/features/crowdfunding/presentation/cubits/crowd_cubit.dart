import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/storage/domain/storage_repo.dart';

import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/comment.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/repos/crowd_repo.dart';
import 'crowd_states.dart';

class CrowdCubit extends Cubit<CrowdState> {
  final CrowdRepo crowdRepo;
  final StorageRepo storageRepo;

  CrowdCubit({
    required this.crowdRepo,
    required this.storageRepo,
  }) : super(CrowdInitial());

  // ===============================
  // 📥 FETCH FEED
  // ===============================
  Future<void> fetchAllCrowds() async {
    try {
      emit(CrowdLoading());
      final crowds = await crowdRepo.fetchAllPosts();
      emit(CrowdLoaded(crowds));
    } catch (e) {
      emit(CrowdError("Failed to fetch feed"));
    }
  }

  // ===============================
  // 🆕 CREATE POST (FIXED)
  // ===============================
  Future<void> createCrowdPost({
    required String text,
    required Uint8List imageBytes,
    required double target,
    required String uId,
    required String uName,
    required String customFileName, // ✅ NEW
  }) async {
    try {
      emit(CrowdUploading());

      // ✅ SAFETY: put files inside user folder
      final safeUser = uName
          .toLowerCase()
          .replaceAll('@', '_')
          .replaceAll('.', '_');

      final String filePath = "$safeUser/$customFileName";

      // ✅ USE PASSED FILENAME (NO HARDCODED .JPG)
      final imageUrl = await storageRepo.uploadPostImageMobile(
        imageBytes,
        filePath,
      );

      if (imageUrl == null) {
        emit(CrowdError("Media upload failed"));
        return;
      }

      final post = CrowdPost(
        id: '',
        userId: uId,
        userName: uName,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        targetAmount: target,
        raisedAmount: 0,
        likes: [],
      );

      await crowdRepo.createPost(post);
      await fetchAllCrowds();
    } catch (e) {
      emit(CrowdError(e.toString()));
    }
  }

  // ===============================
  // 💰 DONATION
  // ===============================
  Future<void> donate(
    String crowdId,
    String donorName,
    double amount,
  ) async {
    try {
      await crowdRepo.donateToPost(crowdId, donorName, amount);
      fetchAllCrowds();
    } catch (e) {
      emit(CrowdError(e.toString()));
    }
  }

  // ===============================
  // 🗑 DELETE POST
  // ===============================
  Future<void> deleteCrowd(String postId) async {
    try {
      emit(CrowdLoading());
      await crowdRepo.deletePost(postId);
      await fetchAllCrowds();
    } catch (e) {
      emit(CrowdError("Failed to delete post"));
    }
  }

  // ===============================
  // 💬 COMMENTS
  // ===============================
  Future<void> addComment(
    String postId,
    Comment comment,
  ) async {
    try {
      await crowdRepo.addComment(postId, comment);
    } catch (e) {
      emit(CrowdError(e.toString()));
    }
  }

  Future<void> deleteComment(
    String postId,
    String commentId,
  ) async {
    try {
      await crowdRepo.deleteComment(postId, commentId);
    } catch (e) {
      emit(CrowdError(e.toString()));
    }
  }

  // ===============================
  // ❤️ LIKE / UNLIKE (OPTIMISTIC)
  // ===============================
  Future<void> toggleLike(String postId, String userId) async {
    if (state is! CrowdLoaded) return;

    final currentState = state as CrowdLoaded;
    final posts = List<CrowdPost>.from(currentState.crowds);

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    final isLiked = post.likes.contains(userId);

    final updatedLikes = List<String>.from(post.likes);
    if (isLiked) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }

    final updatedPost = CrowdPost(
      id: post.id,
      userId: post.userId,
      userName: post.userName,
      text: post.text,
      imageUrl: post.imageUrl,
      timestamp: post.timestamp,
      targetAmount: post.targetAmount,
      raisedAmount: post.raisedAmount,
      likes: updatedLikes,
    );

    posts[index] = updatedPost;
    emit(CrowdLoaded(posts));

    try {
      await crowdRepo.toggleLikePost(postId, userId);
    } catch (_) {
      // optional rollback ignored
    }
  }
}
