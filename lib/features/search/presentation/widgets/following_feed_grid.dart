import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/utlis/media_url.dart';

import '../../../crowdfunding/domain/entities/crowd_post.dart';
import '../../../crowdfunding/presentation/pages/post_detail_page.dart';
import 'package:nri_trial1_clean/components/my_media_grid_tile.dart';

class FollowingFeedGrid extends StatefulWidget {
  final List<String> followingList;

  const FollowingFeedGrid({
    super.key,
    required this.followingList,
  });

  @override
  State<FollowingFeedGrid> createState() => _FollowingFeedGridState();
}

class _FollowingFeedGridState extends State<FollowingFeedGrid> {
  List<CrowdPost>? _posts;

  @override
  void initState() {
    super.initState();
    if (widget.followingList.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final data = await Supabase.instance.client
        .from('posts')
        .select()
        .inFilter('user_id', widget.followingList) // ✅ filter in DB not in dart
        .order('timestamp', ascending: false);

    if (mounted) {
      setState(() {
        _posts = (data as List).map((p) => CrowdPost.fromJson(p, p['id'].toString())).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.followingList.isEmpty) {
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

    if (_posts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts!.isEmpty) {
      return const Center(
        child: Text("No posts from people you follow yet."),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
            ),
            child: MyMediaGridTile(
              url: MediaUrl.convert(post.imageUrl), // ✅ Cloudflare
            ),
          );
        },
      ),
    );
  }
}