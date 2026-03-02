import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

   return Padding(
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14), // ✅ top & bottom space
  child: Row(
  

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 LEFT SIDE (flexible)
          Expanded(
            child: Wrap(
              spacing: 10, // space BETWEEN groups only
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // ❤️ LIKE + COUNT (GROUPED — NO GAP)
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

                // 💬 COMMENTS + COUNT
                InkWell(
                  onTap: () => showCommentSheet(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      const SizedBox(width: 6),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client
                            .from('comments')
                            .stream(primaryKey: ['id'])
                            .eq('post_id', post.id),
                        builder: (_, snapshot) {
                          final count =
                              snapshot.hasData ? snapshot.data!.length : 0;
                          return Text(
                            "$count",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 💰 TARGET AMOUNT
                if (post.targetAmount > 0)
                  Text(
                    "₹${post.targetAmount} needed",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

// 🔹 RIGHT SIDE (SUPPORT – TEXT + ICON ONLY)
if (post.targetAmount > 0)
  InkWell(
onTap: () => showDonationSheet(context, post),    borderRadius: BorderRadius.circular(20),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Icon(
          Icons.volunteer_activism,
          size: 20,
          color: Colors.green,
        ),
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
