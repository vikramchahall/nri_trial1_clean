import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/crowd_post.dart';
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

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMobileSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    }
  }

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
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    final bool canDelete =
        (user != null && user.isAdmin && user.uid == widget.crowdPost.userId);

    // 🔥 CORE LOGIC
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
          // 👤 HEADER
          ListTile(
            leading: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.crowdPost.userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final String? url = data['profileImageUrl'];

                  return CircleAvatar(
                    backgroundImage:
                        (url != null && url.isNotEmpty)
                            ? NetworkImage(url)
                            : null,
                    child: (url == null || url.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  );
                }
                return const CircleAvatar(child: Icon(Icons.person));
              },
            ),
            title: Text(
              "@${widget.crowdPost.userName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: canDelete
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
                  )
                : null,
          ),

          // 🖼 IMAGE
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Image.network(
              widget.crowdPost.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
          ),

          // 💰 PROGRESS (ONLY FOR DONATION POSTS)
          if (isDonationPost)
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    color: Colors.green,
                    minHeight: 12,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Raised: ₹${widget.crowdPost.raisedAmount}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      Text(
                          "Goal: ₹${widget.crowdPost.targetAmount}"),
                    ],
                  ),
                ],
              ),
            ),

          // 🔘 ACTION ROW
          Row(
            children: [
              if (isDonationPost) ...[
                IconButton(
                  onPressed: () => _showDonationDialog(context),
                  icon: const Icon(Icons.volunteer_activism,
                      color: Colors.redAccent),
                ),
                const Text("Donate"),
                const SizedBox(width: 20),
              ],
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrowdHistoryPage(
                        postId: widget.crowdPost.id),
                  ),
                ),
                icon: const Icon(Icons.history),
              ),
              const Text("History"),
            ],
          ),

          // 📝 CAPTION
          Padding(
            padding: const EdgeInsets.all(15.0),
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
