import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/utlis/date_formatter.dart';
import 'package:nri_trial1_clean/components/square_media_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class OfficialFeed extends StatelessWidget {
  const OfficialFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = context.read<AuthCubit>().currentUser;
    final canDelete = user?.isDC ?? false;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('official_updates')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .limit(50),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final updates = snapshot.data!;
        if (updates.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text("No official updates yet."),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          itemCount: updates.length,
          itemBuilder: (_, index) {
            final data = updates[index];
            final hasMedia = data['media_url'] != null &&
                data['media_type'] != null;

            return Container(
              key: ValueKey(data['id']),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ✅ TITLE + DELETE BUTTON AT TOP
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 6, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (canDelete)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                final confirm = await _confirmDelete(context);
                                if (confirm) await _deleteOfficialPost(data);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // ✅ MEDIA (full width, no side padding)
                  if (hasMedia)
                    SquareMediaBox(
                      url: "${data['media_url']}?v=${data['timestamp']}",
                      type: data['media_type'],
                    ),

                  // ✅ MESSAGE + DATE BELOW
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((data['message'] ?? '').toString().isNotEmpty)
                          Text(
                            data['message'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          formatDate(data['timestamp']),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ================= CONFIRM DIALOG =================
Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete post?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

// ================= DELETE LOGIC =================
Future<void> _deleteOfficialPost(Map<String, dynamic> data) async {
  final supabase = Supabase.instance.client;

  if (data['media_url'] != null) {
    final uri = Uri.parse(data['media_url']);
    final path = uri.pathSegments
        .skipWhile((e) => e != 'official_media')
        .skip(1)
        .join('/');
    await supabase.storage.from('official_media').remove([path]);
  }

  await supabase
      .from('official_updates')
      .delete()
      .eq('id', data['id']);
}