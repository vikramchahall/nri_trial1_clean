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
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // AppBar
              SliverAppBar(
                title: const Text(
                  "OFFICIAL UPDATES",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[900],
                elevation: 0,
                floating: true,
                pinned: true,
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
              
              // Collapsible UserCounter
              SliverToBoxAdapter(
                child: const UserCounter(),
              ),
              
              // Pinned TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
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
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Latest Announcements Tab
              ListView(
                padding: EdgeInsets.zero,
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
      ),
    );
  }
}

// Custom delegate to make TabBar sticky
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey[50],
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}