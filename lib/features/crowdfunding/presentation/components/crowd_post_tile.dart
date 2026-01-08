import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/crowd_post.dart';
import '../../domain/entities/comment.dart';
import '../cubits/crowd_cubit.dart';
import '../pages/crowd_history_page.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/services/payment_gateway.dart' as gateway;

class CrowdPostTile extends StatefulWidget {
  final CrowdPost crowdPost;
  const CrowdPostTile({super.key, required this.crowdPost});

  @override
  State<CrowdPostTile> createState() => _CrowdPostTileState();
}

class _CrowdPostTileState extends State<CrowdPostTile> {
  late Razorpay _razorpay;
  double _lastAmount = 0;

  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobileSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
  }

  // =========================
  // 💬 COMMENT TRAY
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Comments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.crowdPost.id)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  final currentUser =
                      context.read<AuthCubit>().currentUser;

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data =
                          comments[index].data() as Map<String, dynamic>;
                      final commentId = comments[index].id;

                      final bool canDelete =
                          (currentUser != null &&
                              (currentUser.uid == data['userId'] ||
                                  currentUser.uid ==
                                      widget.crowdPost.userId));

                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 15,
                          child: Icon(Icons.person, size: 15),
                        ),
                        title: Text(
                          "@${data['userName']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(data['text']),
                        trailing: canDelete
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                onPressed: () => context
                                    .read<CrowdCubit>()
                                    .deleteComment(
                                        widget.crowdPost.id, commentId),
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
  // 💳 PAYMENT LOGIC
  // =========================
  void _handleMobileSuccess(PaymentSuccessResponse response) {
    _onPaymentSuccess();
  }

  void _onPaymentSuccess() {
    final user = context.read<AuthCubit>().currentUser;

    final String donorName =
        (user != null && user.username.trim().isNotEmpty)
            ? user.username
            : "Anonymous Donor";

    context.read<CrowdCubit>().donate(
          widget.crowdPost.id,
          donorName,
          _lastAmount,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Donation Successful!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startPayment(double amount) {
    _lastAmount = amount;
    const String myKey = 'rzp_test_Rxm27dLhNpIVZT';

    if (kIsWeb) {
      gateway.openRazorpayWeb(
        key: myKey,
        amount: (amount * 100).toInt(),
        name: 'Village Help',
        description: 'Donation',
        onSuccess: () => _onPaymentSuccess(),
      );
    } else {
      final options = {
        'key': myKey,
        'amount': (amount * 100).toInt(),
        'name': 'Village Help',
        'description': 'Donation',
      };

      _razorpay.open(options);
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    if (!kIsWeb) _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    final bool canDeletePost =
        (currentUser != null &&
            currentUser.isAdmin &&
            currentUser.uid == widget.crowdPost.userId);

    final bool isDonationPost = widget.crowdPost.targetAmount > 0;

    final double progress = isDonationPost
        ? widget.crowdPost.raisedAmount /
            widget.crowdPost.targetAmount
        : 0;

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
            trailing: canDeletePost
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
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

          if (isDonationPost)
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    color: Colors.green,
                    minHeight: 12,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Raised: ₹${widget.crowdPost.raisedAmount}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      Text("Goal: ₹${widget.crowdPost.targetAmount}"),
                    ],
                  ),
                ],
              ),
            ),

          // 🔘 ACTION ROW (FIXED)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isDonationPost)
                  InkWell(
                    onTap: () => _showDonationDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.volunteer_activism,
                            color: Colors.redAccent, size: 20),
                        SizedBox(width: 4),
                        Text("Donate"),
                      ],
                    ),
                  ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.crowdPost.id)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return InkWell(
                      onTap: () => _showCommentTray(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            count == 0
                                ? "0 comments"
                                : "View $count comments",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                if (isDonationPost)
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CrowdHistoryPage(
                            postId: widget.crowdPost.id),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 4),
                        Text("History"),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(widget.crowdPost.text),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<CrowdCubit>()
                  .deleteCrowd(widget.crowdPost.id);
              Navigator.pop(context);
            },
            child:
                const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDonationDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Amount"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: "₹ "),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                _startPayment(amount);
              }
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }
}
