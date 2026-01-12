import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/components/my_bio_box.dart';

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
              title: Text("@${user.username}"),
              actions: [
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
            body: Column(
              children: [
                const SizedBox(height: 25),

                // ✅ PROFILE IMAGE (CACHE-BUSTED)
                Center(
                  child: ClipOval(
                    child: Image.network(
                      // Cache buster forces browser refresh
                      "${user.profileImageUrl}?v=${DateTime.now().millisecondsSinceEpoch}",
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          size: 72,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ROLE BADGE
                Text(
                  user.isAdmin
                      ? "VILLAGE HEAD"
                      : "COMMUNITY SUPPORTER",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ✅ LOCATION (ONLY FOR SARPANCH)
                if (user.userType == 'Sarpanch')
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        Text(
                          " ${user.town}, ${user.city}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 25),

                // BIO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: MyBioBox(text: user.bio),
                ),
              ],
            ),
          );
        }

        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const Scaffold(
          body: Center(child: Text("Profile error")),
        );
      },
    );
  }
}
