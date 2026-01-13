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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👤 Header (edge-to-edge)
        CrowdPostHeader(post: crowdPost),

        // 🎥 Media (square, full width)
        CrowdPostMedia(post: crowdPost),

        // ❤️ Actions
        CrowdPostActions(post: crowdPost),

        // 📝 Caption
        if (crowdPost.text.trim().isNotEmpty)
Padding(
  padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
  child: Text(
    crowdPost.text,
    style: const TextStyle(fontSize: 14),
  ),
),

        // ➖ Thin divider between posts (Instagram style)
        const Divider(height: 1, thickness: 0.3),
      ],
    );
  }
}
