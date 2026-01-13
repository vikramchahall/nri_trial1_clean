import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class CrowdPostHeader extends StatelessWidget {
  final CrowdPost post;

  const CrowdPostHeader({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    final canDelete =
        currentUser?.uid == post.userId || (currentUser?.isDC ?? false);

   return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: ListTile(
    contentPadding: EdgeInsets.zero,
    leading: _ProfileAvatar(userId: post.userId),
    title: Text(
      post.userName,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Text(
      DateFormat('dd MMM, yyyy').format(post.timestamp),
      style: const TextStyle(fontSize: 11),
    ),
    trailing: canDelete
        ? IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          )
        : null,
  ),
);

    
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text(
          "This action cannot be undone.\nAre you sure you want to delete this post?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<CrowdCubit>().deleteCrowd(post.id);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 👤 PROFILE AVATAR (isolated widget)
class _ProfileAvatar extends StatelessWidget {
  final String userId;

  const _ProfileAvatar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final user = snapshot.data!.first;
          final String? url = user['profile_image_url'];

          return CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: (url != null && url.isNotEmpty)
                ? NetworkImage("$url?v=${DateTime.now().millisecondsSinceEpoch}")
                : null,
            child: (url == null || url.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          );
        }

        return const CircleAvatar(
          radius: 20,
          child: Icon(Icons.person),
        );
      },
    );
  }
}
