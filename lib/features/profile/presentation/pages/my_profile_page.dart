import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'profile_page_content.dart';
import 'profile_edit_page.dart';

class MyProfilePage extends StatelessWidget {
  final String uid;
  const MyProfilePage({super.key, required this.uid});

  // ================= SETTINGS BOTTOM SHEET =================
  void _showSettingsTray(BuildContext context, ProfileUser user) {
    final authCubit = context.read<AuthCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          const Text(
            "Settings",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),

          // ✏️ EDIT PROFILE
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit Bio & Photo"),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileEditPage(user: user),
                ),
              );
            },
          ),

          const Divider(),

          // 🚪 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              authCubit.logout();
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // ✅ SUPABASE STREAM (replaces Firebase)
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = ProfileUser.fromJson(snapshot.data!.first);

        return Scaffold(
          appBar: AppBar(
            title: Text("@${user.username} (Me)"),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsTray(context, user),
              ),
            ],
          ),
          body: ProfilePageContent(user: user),
        );
      },
    );
  }
}
