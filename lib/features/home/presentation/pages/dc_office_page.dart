import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';

class DCOfficePage extends StatelessWidget {
  const DCOfficePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Official Updates"),
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

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('official_updates')
            .stream(primaryKey: ['id'])
            .order('timestamp', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final updates = snapshot.data!;
          if (updates.isEmpty) {
            return const Center(
              child: Text("No official updates yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final data = updates[index];

              // ✅ MODERN GREEN NEWS CARD
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green[700], // Jalandhar Green
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['message'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(data['timestamp']),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
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
    final supabase = Supabase.instance.client;

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

              await supabase.from('official_updates').insert({
                'title': titleController.text.trim(),
                'message': msgController.text.trim(),
              });

              Navigator.pop(dialogContext);
            },
            child: const Text("Post & Notify"),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🗓 FORMAT TIMESTAMP (SAFE)
  // ===============================
  static String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      return DateTime.parse(timestamp.toString())
          .toLocal()
          .toString()
          .split(' ')
          .first;
    } catch (_) {
      return '';
    }
  }
}
