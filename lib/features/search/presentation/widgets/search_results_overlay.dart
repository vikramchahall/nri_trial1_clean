import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/utlis/url_helper.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

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

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Material(
          color: Colors.white,
          child: ListView.builder(
            itemCount: results.length + 1, // ✅ +1 for "Show more" button
            itemBuilder: (context, index) {
              // ✅ Last item = Show more button
              if (index == results.length) {
                if (!state.hasMore) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: state.isLoadingMore
                        ? const CircularProgressIndicator()
                        : TextButton.icon(
                            onPressed: () =>
                                context.read<SearchCubit>().loadMore(),
                            icon: const Icon(Icons.expand_more),
                            label: const Text("Show more"),
                          ),
                  ),
                );
              }

              final user = results[index];
              final imageUrl = user['profile_image_url'];
              final isDC = user['is_dc'] == true;
              final isAdmin = user['is_admin'] == true;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          imageUrl != null && imageUrl.toString().isNotEmpty
                              ? NetworkImage(UrlHelper.getRefreshUrl(imageUrl))
                              : null,
                      child: imageUrl == null ? const Icon(Icons.person) : null,
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
                subtitle: Text(
                  isDC
                      ? "Official Account"
                      : isAdmin
                          ? "Village Head"
                          : "Supporter",
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(uid: user['id']),
                    ),
                  );
                  onClose();
                },
              );
            },
          ),
        );
      },
    );
  }
}