import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/home/presentation/pages/official_updates_page.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_states.dart';
import '../../../auth/domain/entities/app_user.dart';

import '../../../crowdfunding/presentation/pages/crowd_feed_page.dart';
import '../../../crowdfunding/presentation/pages/upload_crowd_page.dart';
import '../../../profile/presentation/pages/my_profile_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../presentation/pages/official_updates_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        AppUser? user;
        if (state is Authenticated) {
          user = state.user;
        }

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Widget> pages = [
          const CrowdFeedPage(),        // Home
          const SearchPage(),           // Search
          
          const OfficialUpdatesPage(),         // Official
          MyProfilePage(uid: user.uid), // Profile
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),

          // ✅ UNIVERSAL POSTING (HOME TAB ONLY)
          floatingActionButton: (_selectedIndex == 0)
              ? FloatingActionButton(
                  backgroundColor: Colors.green.shade600,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadCrowdPage(),
                    ),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.white),
                )
              : null,

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Follow",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign),
                label: "Updates",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}
