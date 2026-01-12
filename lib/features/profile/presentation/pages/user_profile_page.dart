import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';
import '../../domain/entities/profile_user.dart';
import 'profile_page_content.dart';

class UserProfilePage extends StatefulWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchUserProfile(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final myUid = authCubit.currentUser?.uid ?? "";

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
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
        final bool isFollowing = user.followers.contains(myUid);

        return Scaffold(
          appBar: AppBar(
            title: Text("@${user.username}"),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isFollowing ? Colors.grey[200] : Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    context.read<ProfileCubit>().toggleFollow(
                          myUid,
                          user.uid,
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
  }
}
