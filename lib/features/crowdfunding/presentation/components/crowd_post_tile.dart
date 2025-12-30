import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../pages/crowd_history_page.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'dart:js' as js; // This allows Flutter to talk to Javascript
import 'dart:html' as html; // This allows us to listen for the success message

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
    _razorpay = Razorpay();

    if (!kIsWeb) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    } else {
      // WEB ONLY: Listen for the "PAYMENT_SUCCESS" message from the index.html script
      html.window.onMessage.listen((event) {
        if (event.data == "PAYMENT_SUCCESS") {
           _handlePaymentSuccess(PaymentSuccessResponse("web_id", "web_order", "web_sig", {}));
        }
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final user = context.read<AuthCubit>().currentUser;
    context.read<CrowdCubit>().donate(
      widget.crowdPost.id, 
      user?.email?.split('@')[0] ?? "Verified Donor", 
      _lastAmount
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Successful! Thank you."), backgroundColor: Colors.green),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  void _startPayment(double amount) {
    _lastAmount = amount;
    String myKey = 'rzp_test_Rxm27dLhNpIVZT'; // PASTE KEY HERE

    if (kIsWeb) {
      // WEB: Call the helper function we wrote in index.html
      js.context.callMethod('payWithRazorpay', [
        myKey,
        (amount * 100).toInt(),
        'Village Help',
        'Donation',
        'test@nri.com',
        '9123456789'
      ]);
    } else {
      // MOBILE: Use the standard plugin
      var options = {
        'key': myKey,
        'amount': (amount * 100).toInt(),
        'name': 'Village Help',
        'description': 'Donation',
        'prefill': {'contact': '9123456789', 'email': 'test@nri.com'}
      };
      _razorpay.open(options);
    }
  }
  // This is just for your testing phase on Web
  void _handleWebTestSuccess() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Web Test Mode"),
            content: const Text("On Web Test Mode, did you complete the payment in the pop-up?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handlePaymentSuccess(PaymentSuccessResponse("test_id", "test_order", "test_sig",{}));
                }, 
                child: const Text("Yes, Update Progress Bar")
              ),
            ],
          ),
        );
      }
    });
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
                _startPayment(amount);
              }
            },
            child: const Text("Proceed to Pay"),
          )
        ],
      ),
    );
  }
}