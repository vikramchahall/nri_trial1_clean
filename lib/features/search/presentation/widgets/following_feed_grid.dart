import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../crowdfunding/presentation/pages/post_detail_page.dart';
import 'package:nri_trial1_clean/components/my_media_grid_tile.dart';

class FollowingFeedGrid extends StatelessWidget {
  final List<String> followingList;

  const FollowingFeedGrid({
    super.key,
    required this.followingList,
  });

  @override
  Widget build(BuildContext context) {
    if (followingList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Follow people to see their posts here",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('timestamp'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!
            .where((p) =>
                followingList.contains(p['user_id'].toString()))
            .toList()
          ..sort((a, b) => DateTime.parse(b['timestamp'])
              .compareTo(DateTime.parse(a['timestamp'])));

        if (posts.isEmpty) {
          return const Center(
            child: Text("No posts from people you follow yet."),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index];
            final post = CrowdPost.fromJson(
              postData,
              postData['id'].toString(),
            );

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: post),
                ),
              ),
              child: MyMediaGridTile(url: post.imageUrl),
            );
          },
        );
      },
    );
  }
}
