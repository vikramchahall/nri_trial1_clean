import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrowdHistoryPage extends StatelessWidget {
  final String postId;
  const CrowdHistoryPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donation History")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('donations')
            .stream(primaryKey: ['id'])
            .eq('post_id', postId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final donations = snapshot.data!;

          if (donations.isEmpty) {
            return const Center(child: Text("No donations yet"));
          }

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final data = donations[index];

              return ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text(
                  "${data['donor_name']} contributed ₹${data['amount']}",
                ),
                subtitle: const Text("Verified Payment"),
              );
            },
          );
        },
      ),
    );
  }
}
