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
  // 🆕 CREATE POST
  // ===============================
  Future<void> createCrowdPost({
    required String text,
    required Uint8List imageBytes, // ALREADY SAFE (JPG)
    required double target,
    required String uId,
    required String uName,
  }) async {
    try {
      emit(CrowdUploading());

      final safeUser = uName
          .toLowerCase()
          .replaceAll('@', '_')
          .replaceAll('.', '_');

      // 🔥 ALWAYS SAVE AS JPG (SAFE FOR ALL PLATFORMS)
      final String filePath =
          "$safeUser/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final imageUrl =
          await storageRepo.uploadPostImageMobile(
        imageBytes,
        filePath,
      );

      if (imageUrl == null) {
        emit(CrowdError("Image upload failed"));
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
      await crowdRepo.donateToPost(
        crowdId,
        donorName,
        amount,
      );
      await fetchAllCrowds();
    } catch (e) {
      emit(CrowdError("Donation failed"));
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
}
