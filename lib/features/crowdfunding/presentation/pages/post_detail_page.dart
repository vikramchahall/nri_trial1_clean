import 'package:flutter/material.dart';
import '../components/crowd_post_tile.dart';
import '../../domain/entities/crowd_post.dart';

class PostDetailPage extends StatelessWidget {
  final CrowdPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cause Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      // ✅ Scroll-safe and FEED-CONSISTENT
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔁 REUSE HOME FEED TILE
            CrowdPostTile(crowdPost: post),

            const SizedBox(height: 20),
            const Text(
              "--- End of Details ---",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
