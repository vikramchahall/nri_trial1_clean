import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

import '../widgets/user_counter.dart';
import '../widgets/achievement_plate.dart';
import '../widgets/official_feed.dart';
import '../widgets/official_post_dialog.dart';
import 'user_management_page.dart';  // THIS IS THE NEW IMPORT

class OfficialUpdatesPage extends StatelessWidget {
  const OfficialUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return Scaffold(
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
      body: ListView(
        children: [
          UserCounter(),
          Padding(
            padding: EdgeInsets.only(left: 20, top: 10, bottom: 15),
            child: Text(
              "Past Achievements",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          AchievementPlate(),
          Divider(height: 40),
          Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Text(
              "Latest Announcements",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          OfficialFeed(),
        ],
      ),
    );
  }
}