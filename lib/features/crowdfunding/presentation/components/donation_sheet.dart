import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/utlis/whatsapp_helper.dart';

void showDonationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) => const _DonationSheet(),
  );
}

class _DonationSheet extends StatefulWidget {
  const _DonationSheet();

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

            const SizedBox(height: 16),

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

            const SizedBox(height: 12),
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
                labelText: "Purpose / Cause",
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
