import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../crowdfunding/presentation/components/crowd_post_tile.dart';
import '../../../crowdfunding/presentation/cubits/crowd_cubit.dart';
import '../../../crowdfunding/presentation/cubits/crowd_states.dart';
import '../../../crowdfunding/presentation/pages/upload_crowd_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<CrowdCubit>().fetchAllCrowds();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Village Feed"),

        actions: [
          // 👤 PROFILE (FOR BOTH)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(uid: user!.uid),
              ),
            ),
          ),

          // 🚪 LOGOUT (FOR BOTH)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),

          // ➕ ONLY ADMIN
          if (user?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadCrowdPage(),
                ),
              ),
            ),
        ],
      ),

      body: BlocBuilder<CrowdCubit, CrowdState>(
        builder: (context, state) {
          if (state is CrowdLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CrowdLoaded) {
            final crowds = state.crowds;

            if (crowds.isEmpty) {
              return const Center(child: Text("No causes posted yet."));
            }

            return ListView.builder(
              itemCount: crowds.length,
              itemBuilder: (context, index) {
                return CrowdPostTile(
                  crowdPost: crowds[index],
                  isAdmin: user?.isAdmin ?? false,
                );
              },
            );
          }

          return const Center(child: Text("Error loading feed"));
        },
      ),
    );
  }
}
