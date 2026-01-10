import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/language_cubit.dart';

import 'profile_page_content.dart';
import 'profile_edit_page.dart';

class MyProfilePage extends StatelessWidget {
  final String uid;

  const MyProfilePage({
    super.key,
    required this.uid,
  });

  // ================= LANGUAGE DIALOG (SAFE) =================
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                context
                    .read<LanguageCubit>()
                    .changeLanguage(AppLanguage.english);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              title: const Text("हिंदी"),
              onTap: () {
                context
                    .read<LanguageCubit>()
                    .changeLanguage(AppLanguage.hindi);
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              title: const Text("ਪੰਜਾਬੀ"),
              onTap: () {
                context
                    .read<LanguageCubit>()
                    .changeLanguage(AppLanguage.punjabi);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= SETTINGS BOTTOM SHEET (FIXED) =================
  void _showSettingsTray(BuildContext context, ProfileUser user) {
    // 🔥 STORE CUBITS BEFORE OPENING SHEET
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

          // 🌐 LANGUAGE (SAFE FLOW)
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text("Language / भाषा / ਭਾਸ਼ਾ"),
            onTap: () {
              Navigator.pop(sheetContext);      // 1️⃣ close tray
              _showLanguageDialog(context);     // 2️⃣ open dialog
            },
          ),

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

          // 🚪 LOGOUT (CRASH-SAFE)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(sheetContext); // 1️⃣ close sheet
              authCubit.logout();          // 2️⃣ logout
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = ProfileUser.fromJson(
          snapshot.data!.data() as Map<String, dynamic>,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text("@${user.username}"),
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
