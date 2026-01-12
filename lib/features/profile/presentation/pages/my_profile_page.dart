import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import 'profile_page_content.dart';
import 'profile_edit_page.dart';

class MyProfilePage extends StatefulWidget {
  final String uid;
  const MyProfilePage({super.key, required this.uid});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  @override
  void initState() {
    super.initState();
    // 🔥 ALWAYS fetch MY profile when page opens
    context.read<ProfileCubit>().fetchUserProfile(widget.uid);
  }

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

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
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
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            body: Center(child: Text(state.message)),
          );
        }

        if (state is! ProfileLoaded) {
          return const SizedBox.shrink();
        }

        final ProfileUser user = state.profileUser;

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
