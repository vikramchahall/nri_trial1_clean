import 'package:flutter/material.dart';
import 'package:nri_trial1_clean/utlis/url_helper.dart';

import '../../../profile/presentation/pages/user_profile_page.dart';

class SearchResultsOverlay extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> results;
  final VoidCallback onClose;

  const SearchResultsOverlay({
    super.key,
    required this.isLoading,
    required this.results,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator();
    }

    if (results.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return Material(
      color: Colors.white,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final user = results[index];
          final imageUrl = user['profile_image_url'];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  imageUrl != null && imageUrl.toString().isNotEmpty
                      ? NetworkImage(
                          UrlHelper.getRefreshUrl(imageUrl),
                        )
                      : null,
              child: imageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text("@${user['username']}"),
            subtitle: Text(
              user['is_admin'] == true
                  ? "Village Head"
                  : "Supporter",
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserProfilePage(uid: user['id']),
                ),
              );
              
              onClose();
            },
          );
        },
      ),
    );
  }
}
