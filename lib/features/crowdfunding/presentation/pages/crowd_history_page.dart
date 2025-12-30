import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrowdHistoryPage extends StatelessWidget {
  final String postId;
  const CrowdHistoryPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donation History")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('donations').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final donations = snapshot.data!.docs;
          if (donations.isEmpty) return const Center(child: Text("No donations yet. Be the first!"));

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final data = donations[index];
              return ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text("${data['donorName']} donated ₹${data['amount']}"),
                subtitle: const Text("Verified contribution"),
              );
            },
          );
        },
      ),
    );
  }
}