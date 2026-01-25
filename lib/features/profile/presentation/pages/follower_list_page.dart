import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';


import 'user_profile_page.dart';

class FollowerListPage extends StatelessWidget {
  final List<String> uids;
  final String title;

  const FollowerListPage({
    super.key,
    required this.uids,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: uids.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
              itemCount: uids.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: Supabase.instance.client
                      .from('profiles')
                      .select()
                      .eq('id', uids[index])
                      .single(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        title: Text("Loading..."),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final user = snapshot.data!;
                    final imageUrl =
                        user['profile_image_url'] as String? ?? '';
                    final isDC = user['is_dc'] == true;
                    final isAdmin = user['is_admin'] == true;

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          if (isDC || isAdmin)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: VerificationBadge(
                                isDC: isDC,
                                isAdmin: isAdmin,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text("@${user['username']}"),
                          const SizedBox(width: 4),
                          if (isDC || isAdmin)
                            VerificationBadge(
                              isDC: isDC,
                              isAdmin: isAdmin,
                              size: 14,
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserProfilePage(uid: user['id']),
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