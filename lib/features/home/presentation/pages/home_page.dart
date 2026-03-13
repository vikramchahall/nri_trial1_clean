import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_states.dart';
import '../../../auth/domain/entities/app_user.dart';

import '../../../crowdfunding/presentation/pages/crowd_feed_page.dart';
import '../../../crowdfunding/presentation/pages/upload_crowd_page.dart';
import '../../../profile/presentation/pages/my_profile_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../presentation/pages/official_updates_page.dart';
import 'village_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _fabOpen = false;

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
          const CrowdFeedPage(),
          const SearchPage(),
          const OfficialUpdatesPage(),
          MyProfilePage(uid: user.uid),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),

 floatingActionButton: (_selectedIndex == 0)
    ? Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_fabOpen) ...[
            // Follow your village
            GestureDetector(
              onTap: () {
                setState(() => _fabOpen = false);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VillageListPage()));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: 180, // ✅ fixed width — same for both
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "CONNECT YOUR VILLAGE",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Upload
            GestureDetector(
              onTap: () {
                setState(() => _fabOpen = false);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UploadCrowdPage()));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: 180, // ✅ same width as above
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "UPLOAD A POST",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ✅ + button
          GestureDetector(
            onTap: () => setState(() => _fabOpen = !_fabOpen),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _fabOpen ? Icons.close : Icons.add,
                size: 35,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      )
    : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() {
              _selectedIndex = index;
              _fabOpen = false;
            }),
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Follow"),
              BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Updates"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}