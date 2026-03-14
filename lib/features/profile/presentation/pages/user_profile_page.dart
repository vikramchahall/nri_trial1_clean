import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../../data/supabase_profile_repo.dart';
import '../../../storage/data/supabase_storage_repo.dart';
import '../../domain/entities/profile_user.dart';

import 'profile_page_content.dart';

class UserProfilePage extends StatelessWidget {
  final String uid; // UID of the searched user
  const UserProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final myUid = authCubit.currentUser!.uid;

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

          // 🔥 WRAP EVERYTHING IN STREAMBUILDER TO AUTO-REFRESH
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('id', uid),
            builder: (context, snapshot) {
              // Use fresh follower data if available
              List<String> currentFollowers = user.followers;
              
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final freshData = snapshot.data!.first;
                final followersRaw = freshData['followers'];
                if (followersRaw is List) {
                  currentFollowers = List<String>.from(followersRaw);
                }
              }

              final bool isFollowing = currentFollowers.contains(myUid);

              return Scaffold(
                appBar: AppBar(
                  title: Text("${user.username}"),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.grey[200]
                              : Colors.green[600],
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          context.read<ProfileCubit>().toggleFollow(
                                myUid,
                                uid,
                                authCubit,
                              );
                        },
                        child: Text(
                          isFollowing ? "Unfollow" : "Follow",
                          style: TextStyle(
                            color: isFollowing ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: ProfilePageContent(user: user),
              );
            },
          );
        },
      ),
    );
  }
}