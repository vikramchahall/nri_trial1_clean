import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../domain/entities/profile_user.dart';
import '../cubits/profile_cubit.dart';
import 'profile_page_content.dart';

class UserProfilePage extends StatelessWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    final String myUid = currentUser?.uid ?? "";

    return StreamBuilder<List<Map<String, dynamic>>>(
      // ✅ SUPABASE STREAM (replaces Firebase DocumentSnapshot)
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

        // Am I following this user?
        final bool isFollowing = user.followers.contains(myUid);

        return Scaffold(
          appBar: AppBar(
            title: Text("@${user.username}"),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isFollowing ? Colors.grey[200] : Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      context
                          .read<ProfileCubit>()
                          .toggleFollow(myUid, uid);
                    },
                    child: Text(
                      isFollowing ? "Unfollow" : "Follow",
                      style: TextStyle(
                        color:
                            isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
