import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/profile_user.dart';
import '../../../../components/my_bio_box.dart';

// ✅ THESE MUST BE WIDGET FILES
import 'follower_list_page.dart';
import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../crowdfunding/presentation/pages/post_detail_page.dart';

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
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: user.profileImageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.profileImageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Colors.grey),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data?.docs ?? [];

              if (posts.isEmpty) {
                return const Center(
                  child: Text("No causes posted yet."),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(5),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final postData =
                      posts[index].data() as Map<String, dynamic>;

                  // 🔁 Convert Firestore doc → CrowdPost
                  final post = CrowdPost.fromJson(
                    postData,
                    posts[index].id,
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(post: post),
                        ),
                      );
                    },
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
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
