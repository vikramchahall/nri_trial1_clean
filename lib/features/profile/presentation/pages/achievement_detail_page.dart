import 'package:flutter/material.dart';

class AchievementDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const AchievementDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Eye-appealing Header Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: data['image_url'] != null 
                ? Image.network(data['image_url'], fit: BoxFit.cover)
                : Container(color: Colors.green[800]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    data['full_details'] ?? "No further details provided.",
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 100), // Spacing at bottom
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}