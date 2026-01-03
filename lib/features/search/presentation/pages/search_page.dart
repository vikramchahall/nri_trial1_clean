import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _searchResults;

  void _executeSearch(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    setState(() {
      _searchResults = FirebaseFirestore.instance
          .collection('users')
          .where('isAdmin', isEqualTo: true) // ✅ VERIFIED ADMINS ONLY
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThanOrEqualTo: '$q\uf8ff')
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Search verified village heads...",
            border: InputBorder.none,
          ),
          onChanged: _executeSearch,
        ),
      ),
      body: _searchResults == null
          ? const Center(
              child: Text("Search for verified Village Heads"),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _searchResults,
              builder: (context, snapshot) {
                // 🔴 Firestore errors (index issues, permission errors)
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Firestore Error:\n${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text("No verified users found"),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;

                    final String? imageUrl =
                        userData['profileImageUrl'];

                    return ListTile(
                      // ✅ PROFILE IMAGE FIX
                      leading: Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: ClipOval(
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.person,
                                          color: Colors.white),
                                )
                              : const Icon(Icons.person,
                                  color: Colors.white),
                        ),
                      ),

                      title: Text("@${userData['username']}"),
                      subtitle: const Text("Village Head"),

                      onTap: () {
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
    );
  }
}
