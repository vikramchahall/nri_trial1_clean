import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/utlis/url_helper.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_states.dart' as app_auth;
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../../../crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/components/my_media_grid_tile.dart';

import '../../../crowdfunding/presentation/pages/post_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _results = [];


  void _clearSearch() {
  _searchController.clear();
  setState(() {
    _isSearching = false;
    _isLoading = false;
    _results.clear();
  });
}


  // =========================
  // 🔍 SEARCH HANDLER
  // =========================
  Future<void> _onSearchChanged(String query) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _results.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .ilike('username', '%$q%');

      setState(() {
        _results = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================
  // 🧱 UI (LISTENS TO AUTH)
  // =========================
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, app_auth.AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is app_auth.Authenticated ? authState.user : null;

        final followingList = currentUser?.following ?? [];

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
              // 🔥 FOLLOWING GRID (DISCOVERY FEED)
              _buildFollowingFeed(followingList),

              // 🔍 SEARCH OVERLAY
              if (_isSearching) _buildSearchResults(),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // 📰 FOLLOWING GRID (STEP 2)
  // =========================
 Widget _buildFollowingFeed(List<String> followingList) {
  if (followingList.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Follow people to see their posts here", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  return StreamBuilder<List<Map<String, dynamic>>>(
    // 1. Remove the .in_ filter from here (Supabase stream doesn't support it)
    stream: Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('timestamp'), 
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      // 2. THE FIX: Filter the data manually using Dart logic
      // Only keep posts where the 'user_id' is inside our 'followingList'
      final filteredPosts = snapshot.data!.where((post) {
        return followingList.contains(post['user_id'].toString());
      }).toList();

      if (filteredPosts.isEmpty) {
        return const Center(child: Text("No posts from people you follow yet."));
      }

      // 3. Sort Descending (Newest First)
      filteredPosts.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, 
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final postData = filteredPosts[index];
          final post = CrowdPost.fromJson(postData, postData['id'].toString());
          
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
            ),
            child: MyMediaGridTile(url: post.imageUrl),
          );
        },
      );
    },
  );
}
  // =========================
  // 🔍 SEARCH RESULTS
  // =========================
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const LinearProgressIndicator();
    }

    if (_results.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return Material(
      color: Colors.white,
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final userData = _results[index];
          final imageUrl = userData['profile_image_url'];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  (imageUrl != null && imageUrl.toString().isNotEmpty)
                      ? NetworkImage(
                          UrlHelper.getRefreshUrl(imageUrl),
                        )
                      : null,
              child: (imageUrl == null || imageUrl.toString().isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text("@${userData['username']}"),
            subtitle: Text(
              userData['is_admin'] == true ? "Village Head" : "Supporter",
            ),
onTap: () async {
  FocusScope.of(context).unfocus();

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => UserProfilePage(uid: userData['id']),
    ),
  );

  // 🔥 CLEAR SEARCH WHEN COMING BACK
  _clearSearch();
},

          );
        },
      ),
    );
  }
}
