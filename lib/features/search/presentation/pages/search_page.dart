import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../crowdfunding/presentation/pages/post_detail_page.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  Stream<QuerySnapshot>? _searchResults;
  bool _isSearching = false;

  // =========================
  // 🔍 SEARCH HANDLER
  // =========================
  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThanOrEqualTo: '$q\uf8ff')
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search people...",
            border: InputBorder.none,
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged("");
                    },
                  )
                : const Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
        ),
      ),

      // =========================
      // 🧱 BODY (STACK)
      // =========================
      body: Stack(
        children: [
          // 🔹 FOLLOWING POSTS GRID
          _buildFollowingGrid(currentUser?.following ?? []),

          // 🔹 SEARCH RESULTS OVERLAY
          if (_isSearching)
            Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _searchResults,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final imageUrl = userData['profileImageUrl'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text("@${userData['username']}"),
                        subtitle: Text(
                          userData['isAdmin'] == true
                              ? "Village Head"
                              : "Supporter",
                        ),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfilePage(uid: userData['uid']),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // 🟦 FOLLOWING POSTS GRID
  // =========================
  Widget _buildFollowingGrid(List<String> followingList) {
    if (followingList.isEmpty) {
      return const Center(
        child: Text(
          "Follow people to see posts here",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', whereIn: followingList)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No posts yet"));
        }

        // ✅ Sort newest first (NO index)
        docs.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp).toDate();
          final bTime = (b['timestamp'] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final post = CrowdPost.fromJson(
              docs[index].data() as Map<String, dynamic>,
              docs[index].id,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 🖼 POST IMAGE
                  Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),

                  // 🏷 USERNAME OVERLAY
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      color: Colors.black.withOpacity(0.55),
                      child: Text(
                        "@${post.userName}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
