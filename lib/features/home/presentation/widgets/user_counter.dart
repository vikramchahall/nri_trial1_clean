import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nri_trial1_clean/features/profile/presentation/pages/user_profile_page.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/pages/post_detail_page.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/cubits/crowd_cubit.dart';

class UserCounter extends StatelessWidget {
  const UserCounter({super.key});

  Future<Map<String, dynamic>> _fetchStats() async {
    final supabase = Supabase.instance.client;

    final users = await supabase.from('profiles').select('id');
    final userCount = users.length;

    final allLikes = await supabase.from('likes').select('post_id');
    final Map<String, int> likesPerPost = {};
    for (final l in allLikes) {
      final pid = l['post_id'] as String;
      likesPerPost[pid] = (likesPerPost[pid] ?? 0) + 1;
    }

    String? mostLikedPostId;
    int maxLikes = 0;
    likesPerPost.forEach((pid, count) {
      if (count > maxLikes) {
        maxLikes = count;
        mostLikedPostId = pid;
      }
    });

    Map<String, dynamic>? mostLikedPostRaw;
    Map<String, dynamic>? mostLikedPoster;
    if (mostLikedPostId != null) {
      // Fetch ALL columns so we can construct a CrowdPost
      mostLikedPostRaw = await supabase
          .from('posts')
          .select('*')
          .eq('id', mostLikedPostId!)
          .maybeSingle();

      if (mostLikedPostRaw != null) {
        mostLikedPoster = await supabase
            .from('profiles')
            .select('id, username, profile_image_url')
            .eq('id', mostLikedPostRaw['user_id'])
            .maybeSingle();
      }
    }

    final allPosts = await supabase.from('posts').select('user_id');
    final Map<String, int> postsPerUser = {};
    for (final p in allPosts) {
      final uid = p['user_id'] as String;
      postsPerUser[uid] = (postsPerUser[uid] ?? 0) + 1;
    }

    String? mostActiveUserId;
    int maxPosts = 0;
    postsPerUser.forEach((uid, count) {
      if (count > maxPosts) {
        maxPosts = count;
        mostActiveUserId = uid;
      }
    });

    Map<String, dynamic>? mostActiveProfile;
    if (mostActiveUserId != null) {
      mostActiveProfile = await supabase
          .from('profiles')
          .select('id, username, profile_image_url')
          .eq('id', mostActiveUserId!)
          .maybeSingle();
    }

    return {
      'userCount': userCount,
      'mostLikedPostRaw': mostLikedPostRaw,
      'mostLikedPoster': mostLikedPoster,
      'mostLikedCount': maxLikes,
      'mostActiveProfile': mostActiveProfile,
      'mostActivePosts': maxPosts,
    };
  }

  void _showSpotlight(BuildContext context, Map<String, dynamic> data) {
    final mostLikedPoster = data['mostLikedPoster'];
    final mostLikedPostRaw = data['mostLikedPostRaw'] as Map<String, dynamic>?;
    final mostLikedCount = data['mostLikedCount'] ?? 0;
    final mostActiveProfile = data['mostActiveProfile'];
    final mostActivePosts = data['mostActivePosts'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                const Text(
                  "Community Spotlight",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  "this week",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔥 Most liked post row — opens the POST
            if (mostLikedPoster != null && mostLikedPostRaw != null)
              _SpotlightRow(
                emoji: "🔥",
                label: "Most liked post",
                username: "@${mostLikedPoster['username'] ?? 'unknown'}",
                stat: "$mostLikedCount likes",
                avatarUrl: mostLikedPoster['profile_image_url'] as String?,
                postImageUrl: mostLikedPostRaw['image_url'] as String?,
                onTap: () {
                  Navigator.pop(context);
                  // Use CrowdCubit to fetch the full CrowdPost, then navigate
                  context
                      .read<CrowdCubit>()
                      .getPostById(mostLikedPostRaw['id'] as String)
                      .then((crowdPost) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: crowdPost),
                      ),
                    );
                  });
                },
              ),

            if (mostLikedPoster != null && mostActiveProfile != null)
              Divider(height: 24, color: Colors.grey.shade100),

            // 📸 Most active user row — opens the PROFILE
            if (mostActiveProfile != null)
              _SpotlightRow(
                emoji: "📸",
                label: "Most active volunteer",
                username: "@${mostActiveProfile['username'] ?? 'unknown'}",
                stat: "$mostActivePosts posts",
                avatarUrl: mostActiveProfile['profile_image_url'] as String?,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        uid: mostActiveProfile['id'] as String,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final userCount = data?['userCount'] ?? 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade900, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Counter row — left labels, right number + spotlight button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left column — labels + spotlight button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LIVE COMMUNITY",
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Registered Volunteers",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (data != null) ...[
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _showSpotlight(context, data),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "🏆  View Community Spotlight",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Right column — number centred vertically
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "$userCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===============================
// ROW INSIDE BOTTOM SHEET
// ===============================
class _SpotlightRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String username;
  final String stat;
  final String? avatarUrl;
  final String? postImageUrl;
  final VoidCallback onTap;

  const _SpotlightRow({
    required this.emoji,
    required this.label,
    required this.username,
    required this.stat,
    required this.avatarUrl,
    required this.onTap,
    this.postImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(avatarUrl!)
                : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey, size: 20)
                : null,
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$emoji  $label",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Stat pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stat,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 18),
        ],
      ),
    );
  }
}