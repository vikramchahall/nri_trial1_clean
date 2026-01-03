import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowerListPage extends StatelessWidget {
  final List<String> uids;
  final String title;

  const FollowerListPage({
    super.key,
    required this.uids,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: uids.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
              itemCount: uids.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uids[index])
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const ListTile(title: Text("Loading..."));
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;

                    return ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.person)),
                      title: Text("@${data['username']}"),
                    );
                  },
                );
              },
            ),
    );
  }
}
