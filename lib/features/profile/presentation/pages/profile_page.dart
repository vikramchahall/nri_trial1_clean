import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/components/my_bio_box.dart';
import 'package:nri_trial1_clean/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:nri_trial1_clean/features/profile/presentation/cubits/profile_state.dart';

import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchUserProfile(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.profileUser;

          return Scaffold(
            appBar: AppBar(
              title: Text(user.name.isNotEmpty ? user.name : user.email),
              actions: [
                // Edit button
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileEditPage(user: user))),
                  icon: const Icon(Icons.settings),
                )
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 25),
                // Profile Pic Placeholder
                Center(
                  child: Container(
                    height: 120, width: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                    child: const Icon(Icons.person, size: 72, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 25),
                // Role Badge
                Text(user.isAdmin ? "VILLAGE HEAD" : "COMMUNITY SUPPORTER", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                // Bio Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: MyBioBox(text: user.bio),
                ),
              ],
            ),
          );
        } else if (state is ProfileLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          return const Scaffold(body: Center(child: Text("Profile error")));
        }
      },
    );
  }
}