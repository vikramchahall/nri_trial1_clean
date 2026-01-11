import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

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

  // =========================
  // 🔍 SEARCH HANDLER (SUPABASE)
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
      // 🧱 BODY
      // =========================
      body: _isSearching
          ? _buildSearchResults()
          : const Center(
              child: Text(
                "Search for people by username",
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  // =========================
  // 📄 SEARCH RESULTS LIST
  // =========================
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const LinearProgressIndicator();
    }

    if (_results.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final userData = _results[index];
        final imageUrl = userData['profile_image_url'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                (imageUrl != null && imageUrl.toString().isNotEmpty)
                    ? NetworkImage(imageUrl)
                    : null,
            child: (imageUrl == null || imageUrl.toString().isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text("@${userData['username']}"),
          subtitle: Text(
            userData['is_admin'] == true ? "Village Head" : "Supporter",
          ),
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(uid: userData['id']),
              ),
            );
          },
        );
      },
    );
  }
}
