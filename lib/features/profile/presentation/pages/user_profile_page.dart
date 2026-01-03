import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import 'package:nri_trial1_clean/features/profile/domain/entities/profile_user.dart';
import '../cubits/profile_cubit.dart';
import 'profile_page_content.dart';

class UserProfilePage extends StatelessWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // Get YOUR uid
    final currentUser = context.read<AuthCubit>().currentUser;
    final String myUid = currentUser?.uid ?? "";

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

        // Check if you are in their followers list
        final bool isFollowing = user.followers.contains(myUid);

        return Scaffold(
          appBar: AppBar(
            title: Text("@${user.username}"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
            actions: [
              // THE FOLLOW BUTTON
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
                      // Toggle follow via Cubit
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
