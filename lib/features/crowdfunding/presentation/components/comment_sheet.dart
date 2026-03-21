import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nri_trial1_clean/utlis/media_url.dart';
import 'package:nri_trial1_clean/features/profile/presentation/pages/user_profile_page.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';

import '../../domain/entities/crowd_post.dart';
import '../../domain/entities/comment.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

void showCommentSheet(BuildContext context, CrowdPost post) {
  final crowdCubit = context.read<CrowdCubit>();
  final authCubit = context.read<AuthCubit>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: crowdCubit),
          BlocProvider.value(value: authCubit),
        ],
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _CommentSheet(post: post),
        ),
      );
    },
  ).whenComplete(() {
    // ✅ Sync real count when sheet closes — fixes stale count
    crowdCubit.syncCommentCount(post.id);
  });
}

class _CommentSheet extends StatefulWidget {
  final CrowdPost post;
  const _CommentSheet({required this.post});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>>? _comments;

  @override
  void initState() {
    super.initState();
    _loadComments(); // ✅ load once
  }

  Future<void> _loadComments() async {
    final data = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('post_id', widget.post.id)
        .order('timestamp', ascending: false);

    if (mounted) {
      setState(() => _comments = List<Map<String, dynamic>>.from(data));
    }
  }

  void _addComment() async {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    _controller.clear();

    final comment = Comment(
      id: '',
      postId: widget.post.id,
      userId: user.uid,
      userName: user.username,
      text: text,
      timestamp: DateTime.now(),
    );

    await context.read<CrowdCubit>().addComment(widget.post.id, comment);
    _loadComments(); // ✅ refresh after adding
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 12),

            Flexible(
              child: _comments == null
                  ? const Center(child: CircularProgressIndicator())
                  : _comments!.isEmpty
                      ? const Center(child: Text("No comments yet."))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _comments!.length,
                          itemBuilder: (context, index) {
                            final data = _comments![index];
                            final commentUserId = data['user_id'] ?? '';
                            final canDelete = currentUser != null &&
                                (currentUser.uid == commentUserId ||
                                    currentUser.uid == widget.post.userId);

                            return ListTile(
                              leading: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfilePage(uid: commentUserId),
                                  ),
                                ),
                                child: _ProfileAvatar(userId: commentUserId),
                              ),
                              title: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfilePage(uid: commentUserId),
                                  ),
                                ),
                                child: Text(
                                  "@${data['user_name'] ?? 'unknown'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              subtitle: Text(data['text'] ?? ''),
                              trailing: canDelete
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Delete comment?"),
                                            content: const Text("This action cannot be undone."),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        await context.read<CrowdCubit>().deleteComment(
                                          widget.post.id,
                                          data['id'].toString(),
                                        );
                                        _loadComments(); // ✅ refresh after delete
                                      },
                                    )
                                  : null,
                            );
                          },
                        ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          hintText: "Add a comment...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ✅ No StreamBuilder — fetch once with FutureBuilder
class _ProfileAvatar extends StatelessWidget {
  final String userId;
  const _ProfileAvatar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('profiles')
          .select('profile_image_url, image_version, is_dc, is_admin')
          .eq('id', userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const CircleAvatar(
            radius: 15,
            child: Icon(Icons.person, size: 15),
          );
        }

        final user = snapshot.data!.first;
        final String? url = user['profile_image_url'];
        final int? version = user['image_version'];
        final bool isDC = user['is_dc'] == true;
        final bool isAdmin = user['is_admin'] == true;
        final imageUrl = url != null && url.isNotEmpty
            ? (version != null && version > 0
                ? "${MediaUrl.convert(url)}?v=$version"
                : MediaUrl.convert(url))
            : null;

        return Stack(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
              child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey, size: 15) : null,
            ),
            if (isDC || isAdmin)
              Positioned(
                right: 0,
                bottom: 0,
                child: VerificationBadge(isDC: isDC, isAdmin: isAdmin, size: 14),
              ),
          ],
        );
      },
    );
  }
}