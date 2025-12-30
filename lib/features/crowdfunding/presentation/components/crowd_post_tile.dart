import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/crowdfunding/domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/cubits/crowd_cubit.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/pages/crowd_history_page.dart';

class CrowdPostTile extends StatelessWidget {
  final CrowdPost crowdPost;
  final bool isAdmin; // To show/hide delete button

  const CrowdPostTile({super.key, required this.crowdPost, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // Calculate progress (e.g., 0.5 for 50%)
    double progress = crowdPost.targetAmount > 0 ? (crowdPost.raisedAmount / crowdPost.targetAmount) : 0;

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
          // Header: Name & Delete (Only for Admin)
          ListTile(
            title: Text(crowdPost.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: isAdmin ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => context.read<CrowdCubit>().deleteCrowd(crowdPost.id)) : null,
          ),

          // Main Image
if (crowdPost.imageUrl.isNotEmpty)
  Image.network(
    crowdPost.imageUrl,
    height: 250,
    width: double.infinity,
    fit: BoxFit.cover,
  ),


          // --- PROGRESS SECTION ---
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text("Raised: ₹${crowdPost.raisedAmount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text("Goal: ₹${crowdPost.targetAmount}"),
                  ],
                ),
              ],
            ),
          ),

          // --- ACTION BUTTONS ---
          Row(
            children: [
              IconButton(
                onPressed: () => _showDonationDialog(context),
                icon: const Icon(Icons.volunteer_activism, color: Colors.redAccent),
              ),
              const Text("Donate"),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CrowdHistoryPage(postId: crowdPost.id))),
                icon: const Icon(Icons.history),
              ),
              const Text("History"),
            ],
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(crowdPost.text),
          ),
        ],
      ),
    );
  }

  // Simple Donation Dialog (Simulation)
  void _showDonationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Amount to Donate"),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "₹ ")),
        actions: [
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                // We use a simple name for now, later we use current user name
                context.read<CrowdCubit>().donate(crowdPost.id, "A Supporter", amount);
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }
}