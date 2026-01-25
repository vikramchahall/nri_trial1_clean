import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

import '../widgets/user_counter.dart';
import '../widgets/achievement_plate.dart';
import '../widgets/official_feed.dart';
import '../widgets/official_post_dialog.dart';
import 'user_management_page.dart';

class OfficialUpdatesPage extends StatelessWidget {
  const OfficialUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return DefaultTabController(
      length: 2,
      initialIndex: 0, // Start with Announcements tab (index 1)
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "OFFICIAL UPDATES",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[900],
          elevation: 0,
          actions: [
            if (user?.isDC ?? false)
              IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'User Management',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementPage(),
                  ),
                ),
              ),
            if (user?.isDC ?? false)
              IconButton(
                icon: const Icon(Icons.add_business),
                tooltip: 'Create Announcement',
                onPressed: () => showOfficialPostDialog(context),
              ),
          ],
        ),
        body: Column(
          children: [
            // UserCounter at the very top
            const UserCounter(),
            
            // TabBar
            TabBar(
              labelColor: Colors.green[900],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.green[900],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Latest Announcements"),
                Tab(text: "Past Achievements"),
                
              ],
            ),
            
            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                                    // Latest Announcements Tab
                  ListView(
                    children: const [
                      OfficialFeed(),
                    ],
                  ),
                  // Past Achievements Tab
                  ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: const [
                      AchievementPlate(),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}