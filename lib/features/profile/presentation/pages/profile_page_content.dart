import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile_user.dart';
import '../../../../components/my_bio_box.dart';

// ✅ NEW SMART MEDIA TILE
import '../../../../components/my_media_grid_tile.dart';

// FOLLOWERS / FOLLOWING
import 'follower_list_page.dart';

// POSTS
import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../crowdfunding/presentation/pages/post_detail_page.dart';

// CUBIT
import '../cubits/profile_cubit.dart';

class ProfilePageContent extends StatelessWidget {
  final ProfileUser user;
  const ProfilePageContent({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // ================= PROFILE IMAGE =================
        Center(
          child: ClipOval(
            child: Image.network(
              "${user.profileImageUrl}?v=${DateTime.now().millisecondsSinceEpoch}",
              height: 90,
              width: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                width: 90,
                color: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // ================= FOLLOW STATS =================
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowerListPage(
                      uids: user.followers,
                      title: "Followers",
                    ),
                  ),
                );
              },
              child: _buildStatColumn(
                user.followers.length.toString(),
                "Followers",
              ),
            ),
            const SizedBox(width: 40),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowerListPage(
                      uids: user.following,
                      title: "Following",
                    ),
                  ),
                );
              },
              child: _buildStatColumn(
                user.following.length.toString(),
                "Following",
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ================= BIO =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: MyBioBox(text: user.bio),
        ),

        const Divider(height: 40),

        const Text(
          "Village Causes & History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        // ================= POSTS GRID =================
        Expanded(
          child: FutureBuilder<List<CrowdPost>>(
            future: context.read<ProfileCubit>().fetchUserPosts(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No causes posted yet."),
                );
              }

              final posts = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: post),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      // ✅ SMART MEDIA TILE (IMAGE + VIDEO SUPPORT)
                      child: MyMediaGridTile(
                        url: post.imageUrl,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
