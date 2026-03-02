import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/utlis/whatsapp_helper.dart';


void showDonationSheet(BuildContext context, CrowdPost post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) => _DonationSheet(post: post),
  );
}

class _DonationSheet extends StatefulWidget {
  final CrowdPost post;
  const _DonationSheet({required this.post});

  @override
  State<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<_DonationSheet> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController causeController = TextEditingController();
  bool _whatsappFailed = false;

  // Format phone for display: +91 98765 43210
  String get _displayPhone {
    final digits = widget.post.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      final local = digits.substring(2);
      return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
    }
    return widget.post.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return Padding(
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ SHOW PHYSICAL PHONE NUMBER
            if (widget.post.phoneNumber.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Contact Number",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            _displayPhone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ COPY BUTTON
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.green),
                      tooltip: "Copy number",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _displayPhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Number copied to clipboard"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 4),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Donation Amount",
                prefixText: "₹ ",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: causeController,
              decoration: const InputDecoration(
                labelText: "Purpose / Cause",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                 icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text("Confirm on WhatsApp"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (amountController.text.isEmpty ||
                      causeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  try {
                    await WhatsAppHelper.sendDonation(
                      name: currentUser?.username ?? "User",
                      amount: amountController.text,
                      cause: causeController.text,
                      phoneNumber: widget.post.phoneNumber,
                    );
                  } catch (_) {
                    setState(() => _whatsappFailed = true);
                  }
                },
              ),
            ),

            // ✅ FALLBACK MESSAGE if WhatsApp fails
            if (_whatsappFailed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "WhatsApp couldn't open. Please contact directly: $_displayPhone",
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}