import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/profile/presentation/pages/user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  );
}

class _CommentSheet extends StatefulWidget {
  final CrowdPost post;

  const _CommentSheet({required this.post});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  int _forceRefresh = 0;

  void _addComment() {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    final comment = Comment(
      id: '',
      postId: widget.post.id,
      userId: user.uid,
      userName: user.username,
      text: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    context.read<CrowdCubit>().addComment(widget.post.id, comment);
    _controller.clear();
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(_forceRefresh),
                stream: Supabase.instance.client
                    .from('comments')
                    .stream(primaryKey: ['id'])
                    .eq('post_id', widget.post.id)
                    .order('timestamp', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data = comments[index];
                      final commentUserId = data['user_id'] ?? '';

                      final canDelete = currentUser != null &&
                          (currentUser.uid == commentUserId ||
                              currentUser.uid == widget.post.userId);

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(uid: commentUserId),
                              ),
                            );
                          },
                          child: _ProfileAvatar(userId: commentUserId),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfilePage(uid: commentUserId),
                              ),
                            );
                          },
                          child: _UserNameWithBadge(
                            userId: commentUserId,
                            userName: data['user_name'],
                          ),
                        ),
                        subtitle: Text(data['text'] ?? ''),
                        trailing: canDelete
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Delete comment?"),
                                      content: const Text(
                                        "This action cannot be undone.\nAre you sure?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  context.read<CrowdCubit>().deleteComment(
                                        widget.post.id,
                                        data['id'].toString(),
                                      );

                                  setState(() {
                                    _forceRefresh++;
                                  });
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

/// 👤 PROFILE AVATAR WITH BADGE
class _ProfileAvatar extends StatelessWidget {
  final String userId;

  const _ProfileAvatar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final user = snapshot.data!.first;
          final String? url = user['profile_image_url'];
          final int? version = user['image_version'];
          final bool isDC = user['is_dc'] == true;
          final bool isAdmin = user['is_admin'] == true;

          return Stack(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey[200],
                backgroundImage: (url != null && url.isNotEmpty)
                    ? NetworkImage(
                        version != null && version > 0 ? "$url?v=$version" : url)
                    : null,
                child: (url == null || url.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey, size: 15)
                    : null,
              ),
              if (isDC || isAdmin)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: VerificationBadge(
                    isDC: isDC,
                    isAdmin: isAdmin,
                    size: 14,
                  ),
                ),
            ],
          );
        }

        return const CircleAvatar(
          radius: 15,
          child: Icon(Icons.person, size: 15),
        );
      },
    );
  }
}

/// USERNAME WITH BADGE
class _UserNameWithBadge extends StatelessWidget {
  final String userId;
  final String userName;

  const _UserNameWithBadge({required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId),
      builder: (context, snapshot) {
        final isDC = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!.first['is_dc'] == true
            : false;
        final isAdmin = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!.first['is_admin'] == true
            : false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "@$userName",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (isDC || isAdmin) ...[
              const SizedBox(width: 4),
              VerificationBadge(
                isDC: isDC,
                isAdmin: isAdmin,
                size: 12,
              ),
            ],
          ],
        );
      },
    );
  }
}