import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/crowd_post_tile.dart';
import '../cubits/crowd_cubit.dart';
import '../cubits/crowd_states.dart';
import '../../domain/entities/crowd_post.dart';

class CrowdFeedPage extends StatefulWidget {
  const CrowdFeedPage({super.key});

  @override
  State<CrowdFeedPage> createState() => _CrowdFeedPageState();
}

class _CrowdFeedPageState extends State<CrowdFeedPage> {
  Map<String, dynamic>? _villageFollow;
  List<CrowdPost> _villagePosts = [];
  bool _villageLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<CrowdCubit>().fetchAllCrowds();
    _fetchVillageFollow();
  }

  Future<void> _fetchVillageFollow() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _villageLoading = false);
      return;
    }

    try {
      // ✅ Get which village this user follows
      final followData = await Supabase.instance.client
          .from('village_follows')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (followData == null) {
        if (mounted) setState(() => _villageLoading = false);
        return;
      }

      // ✅ Get posts from that village profile
      final villageProfileId = followData['village_profile_id'] as String;
      final postsData = await Supabase.instance.client
          .from('posts')
          .select('*, likes(user_id)') // ✅ join likes table
          .eq('user_id', villageProfileId)
          .order('timestamp', ascending: false);

      final villagePosts = (postsData as List).map((json) {
        final likesList = (json['likes'] as List?)
                ?.map((l) => l['user_id'].toString())
                .toList() ??
            [];
        return CrowdPost.fromJson(
          {...json, 'likes': likesList},
          json['id'].toString(),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _villageFollow = followData;
          _villagePosts = villagePosts;
          _villageLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching village feed: $e");
      if (mounted) setState(() => _villageLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Column(
  children: [
    const Text(
      "V I L L A G E  F E E D",
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    if (!_villageLoading && _villageFollow != null)
      Text(
        "Welcome to ${[
          if ((_villageFollow!['block_name'] ?? '').toString().isNotEmpty)
            _villageFollow!['block_name'],
          if ((_villageFollow!['city'] ?? '').toString().isNotEmpty)
            _villageFollow!['city'],
        ].join(', ')}",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade600,
        ),
      ),
  ],
),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<CrowdCubit, CrowdState>(
        builder: (context, state) {
          if (state is CrowdLoading && _villageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CrowdLoaded) {
            final allPosts = state.crowds;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CrowdCubit>().fetchAllCrowds();
                await _fetchVillageFollow();
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [

                  // ===============================
                  // 🏡 VILLAGE POSTS SECTION
                  // ===============================
                  if (!_villageLoading && _villageFollow != null) ...[
                    if (_villagePosts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Text(
                          "No posts from your village yet.",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...(_villagePosts
                          .map((post) => CrowdPostTile(crowdPost: post))),

                    // ✅ Divider between village and all posts
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "All Posts",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),
                  ],

                  // ===============================
                  // 📰 ALL POSTS (NORMAL FEED)
                  // ===============================
                  if (allPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("No causes yet.")),
                    )
                  else
                    ...allPosts.map(
                      (post) => CrowdPostTile(crowdPost: post),
                    ),
                ],
              ),
            );
          }

          return const Center(child: Text("Error loading feed"));
        },
      ),
    );
  }
}