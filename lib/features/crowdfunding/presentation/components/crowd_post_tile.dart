import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // IMPORT THIS
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/cubits/crowd_cubit.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/pages/crowd_history_page.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_cubit.dart';


class CrowdPostTile extends StatefulWidget {
  final CrowdPost crowdPost;
  final bool isAdmin;

  const CrowdPostTile({super.key, required this.crowdPost, required this.isAdmin});

  @override
  State<CrowdPostTile> createState() => _CrowdPostTileState();
}

class _CrowdPostTileState extends State<CrowdPostTile> {
  late Razorpay _razorpay;
  double _lastAmount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Important to clean up
    super.dispose();
  }

  // If payment is SUCCESSFUL
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final user = context.read<AuthCubit>().currentUser;
    
    // Only update database IF payment succeeded
    context.read<CrowdCubit>().donate(
      widget.crowdPost.id, 
      user?.email?.split('@')[0] ?? "Verified Donor", 
      _lastAmount
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Successful! Thank you."), backgroundColor: Colors.green),
    );
  }

  // If payment FAILS or is CANCELLED
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  // Launch Razorpay Gateway
  void _startPayment(double amount) {
    _lastAmount = amount;
    var options = {
      'key': 'rzp_test_Rxm27dLhNpIVZT', // PASTE YOUR KEY ID HERE
      'amount': (amount * 100).toInt(), // Razorpay works in Paisa (100 = ₹1)
      'name': 'Village Help Donation',
      'description': 'Cause: ${widget.crowdPost.userName}',
      'prefill': {
        'contact': '8837510630', 
        'email': 'testvikram@razorpay.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.crowdPost.targetAmount > 0 
        ? (widget.crowdPost.raisedAmount / widget.crowdPost.targetAmount) 
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(widget.crowdPost.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: widget.isAdmin ? IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<CrowdCubit>().deleteCrowd(widget.crowdPost.id)) : null,
          ),
          Image.network(widget.crowdPost.imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
          
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green.shade600,
                  minHeight: 12,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Raised: ₹${widget.crowdPost.raisedAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text("Goal: ₹${widget.crowdPost.targetAmount}"),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                onPressed: () => _showDonationDialog(context),
                icon: const Icon(Icons.volunteer_activism, color: Colors.redAccent),
              ),
              const Text("Donate Now"),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CrowdHistoryPage(postId: widget.crowdPost.id))),
                icon: const Icon(Icons.history),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 15),
                child: Text("History"),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.all(15.0), child: Text(widget.crowdPost.text)),
        ],
      ),
    );
  }

  void _showDonationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Amount"),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "₹ ")),
        actions: [
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                _startPayment(amount); // THIS OPENS RAZORPAY
              }
            },
            child: const Text("Proceed to Pay"),
          )
        ],
      ),
    );
  }
}