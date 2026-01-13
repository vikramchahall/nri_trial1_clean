import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/crowd_post.dart';
import '../../domain/entities/comment.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

void showCommentSheet(BuildContext context, CrowdPost post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _CommentSheet(post: post),
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
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Comments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('post_id', widget.post.id)
                  .order('timestamp', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
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

                    final canDelete =
                        currentUser != null &&
                        (currentUser.uid == data['user_id'] ||
                            currentUser.uid == widget.post.userId);

                    return ListTile(
                      leading: const CircleAvatar(
                        radius: 15,
                        child: Icon(Icons.person, size: 15),
                      ),
                      title: Text(
                        "@${data['user_name']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(data['text'] ?? ''),
                      trailing: canDelete
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                              ),
                              onPressed: () => context
                                  .read<CrowdCubit>()
                                  .deleteComment(
                                    widget.post.id,
                                    data['id'].toString(),
                                  ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 15,
              right: 15,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
