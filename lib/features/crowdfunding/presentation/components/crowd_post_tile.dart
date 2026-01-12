import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/crowd_post.dart';
import '../../domain/entities/comment.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../components/my_video_player.dart';

class CrowdPostTile extends StatefulWidget {
  final CrowdPost crowdPost;
  const CrowdPostTile({super.key, required this.crowdPost});

  @override
  State<CrowdPostTile> createState() => _CrowdPostTileState();
}

class _CrowdPostTileState extends State<CrowdPostTile> {
  final TextEditingController commentController = TextEditingController();
  // =========================
  // ⚠️ DELETE CONFIRMATION
  // =========================
  void _confirmDeletePost() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text(
          "This action cannot be undone.\nAre you sure you want to delete this post?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<CrowdCubit>()
                  .deleteCrowd(widget.crowdPost.id);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 💬 COMMENT TRAY
  // =========================
  void _showCommentTray() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
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

                      final canDelete =
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
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(data['text'] ?? ''),
                        trailing: canDelete
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
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
    if (user == null || commentController.text.trim().isEmpty) return;

    final newComment = Comment(
      id: '',
      postId: widget.crowdPost.id,
      userId: user.uid,
      userName: user.username,
      text: commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    context.read<CrowdCubit>().addComment(widget.crowdPost.id, newComment);
    commentController.clear();
  }

  // =========================
  // 📲 WHATSAPP
  // =========================
  void _launchWhatsApp(String name, String amount, String cause) async {
    const phone = "918837510630";

    final message =
        "Hello! My name is $name.\n"
        "I have donated ₹$amount.\n"
        "Purpose: $cause.";

    final url = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

 void _showDonationSheet(BuildContext context) {
  final amountController = TextEditingController();
  final causeController = TextEditingController();
  final currentUser = context.read<AuthCubit>().currentUser;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                "Support This Cause",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🏦 DONATION DETAILS
            const Text(
              "Donations can be made to:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const SelectableText("The Secretary"),
            const SelectableText("Indian Red Cross Society"),
            const SelectableText("Punjab State Branch"),

            const SizedBox(height: 6),

            const SelectableText("Bank: State Bank of Patiala"),
            const SelectableText("A/c No: 5509429xxxx"),
            const SelectableText("Code No: 501xxx"),
            const SelectableText("IFS Code: STBP000xxx"),
            const SelectableText("Jalandhar"),

            const SizedBox(height: 10),

            const Text(
              "Note: After clicking confirm on whatsapp please share the screenshot of payment",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // 💰 AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Donation Amount",
                prefixText: "₹ ",
              ),
            ),

            const SizedBox(height: 12),

            // 📝 PURPOSE / CAUSE
            TextField(
              controller: causeController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: "Purpose / Cause",
                hintText: "e.g. Medical aid, Flood relief",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty ||
                      causeController.text.isEmpty) {
                    return;
                  }

                  Navigator.pop(context);

                  _launchWhatsApp(
                    currentUser?.username ?? "User",
                    amountController.text,
                    causeController.text,
                  );
                },
                child: const Text("Confirm on WhatsApp"),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

  // =========================
  // 🖥 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    final mediaUrl = widget.crowdPost.imageUrl;
    final isVideo =
        mediaUrl.toLowerCase().contains(".mp4") ||
        mediaUrl.toLowerCase().contains(".mov");

    final bool isDonationPost = widget.crowdPost.targetAmount > 0;

    final canDelete =
        currentUser?.uid == widget.crowdPost.userId ||
        (currentUser?.isDC ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 HEADER WITH PROFILE PHOTO
       ListTile(
  leading: StreamBuilder<List<Map<String, dynamic>>>(
    stream: Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.crowdPost.userId),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        final liveUser = snapshot.data!.first;
        final String? url = liveUser['profile_image_url'];

        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: (url != null && url.isNotEmpty)
              ? NetworkImage(
                  "$url?v=${DateTime.now().millisecondsSinceEpoch}",
                )
              : null,
          child: (url == null || url.isEmpty)
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        );
      }

      return const CircleAvatar(
        radius: 20,
        child: Icon(Icons.person),
      );
    },
  ),
  title: Text(
    widget.crowdPost.userName,
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
  subtitle: Text(
    DateFormat('dd MMM, yyyy').format(widget.crowdPost.timestamp),
    style: const TextStyle(fontSize: 11),
  ),
  trailing: canDelete
      ? IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _confirmDeletePost,
        )
      : null,
),


          // 🎥 MEDIA
          GestureDetector(
            onDoubleTap: () {
              if (currentUser == null) return;
              context.read<CrowdCubit>().toggleLike(
                    widget.crowdPost.id,
                    currentUser.uid,
                  );
            },
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: isVideo
                  ? MyVideoPlayer(videoUrl: mediaUrl)
                  : Image.network(mediaUrl, fit: BoxFit.cover),
            ),
          ),

          // ❤️ ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    widget.crowdPost.likes.contains(currentUser?.uid)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.crowdPost.likes.contains(currentUser?.uid)
                        ? Colors.red
                        : Colors.black87,
                  ),
                  onPressed: currentUser == null
                      ? null
                      : () => context.read<CrowdCubit>().toggleLike(
                            widget.crowdPost.id,
                            currentUser.uid,
                          ),
                ),
                Text("${widget.crowdPost.likes.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(width: 16),

StreamBuilder<List<Map<String, dynamic>>>(
  stream: Supabase.instance.client
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('post_id', widget.crowdPost.id),
  builder: (context, snapshot) {
    final count =
        snapshot.hasData ? snapshot.data!.length : 0;

    return InkWell(
      onTap: _showCommentTray,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            Text(
              "$count",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // 💰 TARGET AMOUNT (ONLY IF DONATION POST)
            if (widget.crowdPost.targetAmount > 0) ...[
              const SizedBox(width: 18),
              Text(
                "₹${widget.crowdPost.targetAmount} needed",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
),

                const Spacer(),

                if (isDonationPost)
                  ElevatedButton.icon(
                    onPressed: () => _showDonationSheet(context),
                    icon: const Icon(Icons.volunteer_activism, size: 16),
                    label: const Text("Support"),
                  ),
              ],
            ),
          ),

          if (widget.crowdPost.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.crowdPost.text),
            ),
        ],
      ),
    );
  }
}
