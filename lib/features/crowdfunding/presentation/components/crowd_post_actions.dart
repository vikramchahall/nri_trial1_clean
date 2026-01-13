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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // ❤️ LIKE
          IconButton(
            icon: Icon(
              post.likes.contains(currentUser?.uid)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: post.likes.contains(currentUser?.uid)
                  ? Colors.red
                  : Colors.black87,
            ),
            onPressed: currentUser == null
                ? null
                : () => context.read<CrowdCubit>().toggleLike(
                      post.id,
                      currentUser.uid,
                    ),
          ),
          Text(
            "${post.likes.length}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 16),

          // 💬 COMMENTS COUNT
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('comments')
                .stream(primaryKey: ['id'])
                .eq('post_id', post.id),
            builder: (context, snapshot) {
              final count =
                  snapshot.hasData ? snapshot.data!.length : 0;

              return InkWell(
                onTap: () => showCommentSheet(context, post),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 8),
                      Text(
                        "$count",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // 💰 TARGET AMOUNT
                      if (post.targetAmount > 0) ...[
                        const SizedBox(width: 18),
                        Text(
                          "₹${post.targetAmount} needed",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // 🤝 SUPPORT BUTTON
          if (post.targetAmount > 0)
            ElevatedButton.icon(
              onPressed: () => showDonationSheet(context),
              icon: const Icon(Icons.volunteer_activism, size: 16),
              label: const Text("Support"),
            ),
        ],
      ),
    );
  }
}
