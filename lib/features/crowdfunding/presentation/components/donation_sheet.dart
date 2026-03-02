import 'package:flutter/material.dart';
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

            const SizedBox(height: 8),

            // ✅ NEW SUBTITLE
            const Center(
              child: Text(
                "This will open WhatsApp so you can directly contact the village and arrange your donation.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

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
                labelText: "Add Note",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty ||
                      causeController.text.isEmpty) return;

                  Navigator.pop(context);

                  WhatsAppHelper.sendDonation(
                    name: currentUser?.username ?? "User",
                    amount: amountController.text,
                    cause: causeController.text,
                    phoneNumber: widget.post.phoneNumber,
                  );
                },
                child: const Text("Confirm on WhatsApp"),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}