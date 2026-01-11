import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/crowd_post.dart';
import '../../domain/entities/comment.dart';
import '../cubits/crowd_cubit.dart';
import '../pages/crowd_history_page.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class CrowdPostTile extends StatefulWidget {
  final CrowdPost crowdPost;
  const CrowdPostTile({super.key, required this.crowdPost});

  @override
  State<CrowdPostTile> createState() => _CrowdPostTileState();
}

class _CrowdPostTileState extends State<CrowdPostTile> {
  final commentController = TextEditingController();

  // =========================
  // 💬 COMMENT TRAY (SUPABASE)
  // =========================
  void _showCommentTray(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
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
                    .eq('post_id', widget.crowdPost.id)
                    .order('timestamp', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  final currentUser =
                      context.read<AuthCubit>().currentUser;

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data = comments[index];

                      final bool canDelete =
                          currentUser != null &&
                          (currentUser.uid == data['user_id'] ||
                              currentUser.uid ==
                                  widget.crowdPost.userId);

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
                                      widget.crowdPost.id,
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
                      controller: commentController,
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
      ),
    );
  }

  void _addComment() {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null || commentController.text.isEmpty) return;

    final newComment = Comment(
      id: '',
      postId: widget.crowdPost.id,
      userId: user.uid,
      userName: user.username,
      text: commentController.text,
      timestamp: DateTime.now(),
    );

    context.read<CrowdCubit>().addComment(widget.crowdPost.id, newComment);
    commentController.clear();
  }

  // =========================
  // 📲 WHATSAPP DONATION
  // =========================
  void _launchWhatsApp(String name, String amount) async {
    const phone = "919999999999"; // 🔴 PUT REAL NUMBER
    final message =
        "Hi, my name is $name. I donated ₹$amount for the post by @${widget.crowdPost.userName}. Screenshot attached.";

    final url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showDonationDialog(BuildContext context) {
    final controller = TextEditingController();
    final user = context.read<AuthCubit>().currentUser;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Donation Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Send money to:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const SelectableText("UPI: villagehelp@upi"),
            const SelectableText("Bank: SBI | A/C: 1234567890"),
            const Divider(),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: "₹ "),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _launchWhatsApp(
                  user?.username ?? "User",
                  controller.text,
                );
              }
            },
            child: const Text("Confirm on WhatsApp"),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🖥 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    final bool canDelete =
        currentUser != null &&
        (currentUser.uid == widget.crowdPost.userId ||
            currentUser.isDC);

    final bool isDonationPost = widget.crowdPost.targetAmount > 0;

    final bool isLiked = currentUser != null &&
        widget.crowdPost.likes.contains(currentUser.uid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              "@${widget.crowdPost.userName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: canDelete
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => context
                        .read<CrowdCubit>()
                        .deleteCrowd(widget.crowdPost.id),
                  )
                : null,
          ),

          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              widget.crowdPost.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 40),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionItem(
                  icon: isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: "${widget.crowdPost.likes.length}",
                  color: isLiked ? Colors.red : Colors.grey,
                  onTap: currentUser == null
                      ? null
                      : () => context
                          .read<CrowdCubit>()
                          .toggleLike(
                            widget.crowdPost.id,
                            currentUser.uid,
                          ),
                ),

                if (isDonationPost)
                  _actionItem(
                    icon: Icons.volunteer_activism,
                    label: "Donate",
                    color: Colors.green,
                    onTap: () => _showDonationDialog(context),
                  ),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('comments')
                      .stream(primaryKey: ['id'])
                      .eq('post_id', widget.crowdPost.id),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.length : 0;

                    return _actionItem(
                      icon: Icons.chat_bubble_outline,
                      label: count.toString(),
                      onTap: () => _showCommentTray(context),
                    );
                  },
                ),

                if (isDonationPost)
                  _actionItem(
                    icon: Icons.history,
                    label: "History",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CrowdHistoryPage(
                          postId: widget.crowdPost.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(widget.crowdPost.text),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 10),
            child: Text(
              DateFormat('MMM d, yyyy')
                  .format(widget.crowdPost.timestamp),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    Color color = Colors.grey,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
