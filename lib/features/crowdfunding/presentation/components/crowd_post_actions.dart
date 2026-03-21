import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'comment_sheet.dart';
import 'donation_sheet.dart';

class CrowdPostActions extends StatelessWidget {
  final CrowdPost post;

  const CrowdPostActions({
    super.key,
    required this.post,
  });

  void _sharePost() {
    final url = 'https://connect-nri.github.io/connectnri/?post=${post.id}';
    Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ❤️ LIKE + COUNT
                GestureDetector(
                  onTap: currentUser == null
                      ? null
                      : () => context.read<CrowdCubit>().toggleLike(
                            post.id,
                            currentUser.uid,
                          ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLikedBy(currentUser?.uid ?? '')
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedBy(currentUser?.uid ?? '')
                            ? Colors.red
                            : Colors.black87,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${post.likeCount}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 💬 COMMENTS — ✅ uses post.commentCount,
                InkWell(
                  onTap: () => showCommentSheet(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "${post.commentCount}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 📤 SHARE
                InkWell(
                  onTap: _sharePost,
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(Icons.share_outlined, size: 20),
                ),

                // 💰 TARGET AMOUNT
                if (post.targetAmount > 0)
                  Text(
                    "₹${post.targetAmount} needed",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          // 🔹 RIGHT SIDE — SUPPORT
          if (post.targetAmount > 0)
            InkWell(
              onTap: () => showDonationSheet(context, post),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.volunteer_activism, size: 20, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    "Support",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}