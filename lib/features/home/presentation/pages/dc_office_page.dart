import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';

class DCOfficePage extends StatelessWidget {
  const DCOfficePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DC Office Jalandhar"),
        centerTitle: true,
        actions: [
          // ✅ ONLY DC CAN POST
          if (user?.isDC ?? false)
            IconButton(
              icon: const Icon(Icons.post_add),
              onPressed: () => _showPostUpdateDialog(context),
            ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('dc_updates')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final updates = snapshot.data!.docs;

          if (updates.isEmpty) {
            return const Center(
              child: Text("No official updates yet."),
            );
          }

          return ListView.builder(
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final data =
                  updates[index].data() as Map<String, dynamic>;

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(
                      color: Colors.green.shade700,
                      width: 5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 10),
                    Text(
                      data['date'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===============================
  // 🏛 POST OFFICIAL UPDATE (DC ONLY)
  // ===============================
  void _showPostUpdateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Post Official Update"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Title",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Message",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  msgController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('dc_updates')
                  .add({
                'title': titleController.text.trim(),
                'message': msgController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
                'date': DateTime.now()
                    .toString()
                    .split(' ')
                    .first,
              });

              Navigator.pop(dialogContext);
            },
            child: const Text("Post & Notify"),
          ),
        ],
      ),
    );
  }
}
