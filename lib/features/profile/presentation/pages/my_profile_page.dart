import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_cubit.dart';

import 'profile_page_content.dart';
import 'profile_edit_page.dart';

class MyProfilePage extends StatelessWidget {
  final String uid;

  const MyProfilePage({
    super.key,
    required this.uid,
  });

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
            title: Text("@${user.username} (Me)"),
            actions: [
              // 🚪 LOGOUT BUTTON
              IconButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
              ),

              // ⚙️ SETTINGS BUTTON
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEditPage(user: user),
                  ),
                ),
              ),
            ],
          ),

          // Shared profile content
          body: ProfilePageContent(user: user),
        );
      },
    );
  }
}
