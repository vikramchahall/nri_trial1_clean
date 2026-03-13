import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';

import '../../domain/entities/profile_user.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../../data/supabase_profile_repo.dart';
import '../../../storage/data/supabase_storage_repo.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

import 'profile_page_content.dart';
import 'profile_edit_page.dart';
import 'settings_page.dart';

class MyProfilePage extends StatelessWidget {
  final String uid;
  const MyProfilePage({super.key, required this.uid});

  // ================= SETTINGS BOTTOM SHEET =================
  void _showSettingsTray(
    BuildContext context,
    ProfileUser user,
  ) {
    final authCubit = context.read<AuthCubit>();
    final profileCubit = context.read<ProfileCubit>(); // ✅ GET CUBIT REFERENCE

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
            onTap: () async {
              Navigator.pop(sheetContext);
              
              // ✅ WAIT FOR EDIT PAGE TO CLOSE, THEN REFRESH
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: profileCubit, // ✅ SHARE THE SAME CUBIT
                    child: ProfileEditPage(user: user),
                  ),
                ),
              );
              
              // ✅ REFRESH PROFILE AFTER RETURNING
              profileCubit.fetchUserProfile(uid);
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("App Info & Support"),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),

          const Divider(),

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        profileRepo: SupabaseProfileRepo(),
        storageRepo: SupabaseStorageRepo(),
      )..fetchUserProfile(uid),
      child: BlocBuilder<ProfileCubit, ProfileState>(
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
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${user.username}"),
                  if (user.isDC || user.isAdmin) ...[
                    const SizedBox(width: 6),
                    VerificationBadge(
                      isDC: user.isDC,
                      isAdmin: user.isAdmin,
                      size: 18,
                    ),
                  ],
                ],
              ),
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
      ),
    );
  }
}