import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../components/crowd_post_tile.dart';
import '../../domain/entities/crowd_post.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/cubits/crowd_cubit.dart';

class PostDetailPage extends StatelessWidget {
  final CrowdPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<CrowdPost>(
        future: context.read<CrowdCubit>().getPostById(post.id),
        builder: (context, snapshot) {

          // ⏳ Still loading — show skeleton, NOT stale post
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          // ❌ Error fallback
          if (snapshot.hasError || !snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  CrowdPostTile(crowdPost: post), // fallback only on error
                  const SizedBox(height: 20),
                  const Text("--- End of Details ---",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 50),
                ],
              ),
            );
          }

          // ✅ Fresh data ready
          return SingleChildScrollView(
            child: Column(
              children: [
                CrowdPostTile(crowdPost: snapshot.data!),
                const SizedBox(height: 20),
                const Text("--- End of Details ---",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}