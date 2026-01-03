import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_states.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../crowdfunding/presentation/pages/crowd_feed_page.dart';
import '../../../crowdfunding/presentation/pages/upload_crowd_page.dart';
import '../../../profile/presentation/pages/my_profile_page.dart';
import '../../../search/presentation/pages/search_page.dart';

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
        // ✅ GET USER FROM STATE (NOT FROM CUBIT VARIABLE)
        AppUser? user;
        if (state is Authenticated) {
          user = state.user;
        }

        // 🔐 SAFETY: auth not ready yet
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Widget> pages = [
          const CrowdFeedPage(),
          const SearchPage(),
          MyProfilePage(uid: user.uid),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),

          // ➕ ADMIN ICON — NOW REACTS TO ROLE CHANGES
          floatingActionButton:
              (user.isAdmin && _selectedIndex == 0)
                  ? FloatingActionButton(
                      backgroundColor: Colors.green.shade600,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadCrowdPage(),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                      ),
                    )
                  : null,

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) =>
                setState(() => _selectedIndex = index),
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
                label: "Search",
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
