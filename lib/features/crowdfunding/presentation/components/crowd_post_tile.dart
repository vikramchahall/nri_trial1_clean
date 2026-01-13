import 'package:flutter/material.dart';

import '../../domain/entities/crowd_post.dart';
import 'crowd_post_header.dart';
import 'crowd_post_media.dart';
import 'crowd_post_actions.dart';

class CrowdPostTile extends StatelessWidget {
  final CrowdPost crowdPost;

  const CrowdPostTile({
    super.key,
    required this.crowdPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Header
          CrowdPostHeader(post: crowdPost),

          // 🎥 Media
          CrowdPostMedia(post: crowdPost),

          // ❤️ Actions (likes, comments, support)
          CrowdPostActions(post: crowdPost),

          // 📝 Text
          if (crowdPost.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(crowdPost.text),
            ),
        ],
      ),
    );
  }
}
