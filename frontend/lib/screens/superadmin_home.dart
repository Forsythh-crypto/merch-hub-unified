import 'package:flutter/material.dart';
import '../models/user_role.dart';
import './superadmin_dashboard.dart';
import './superadmin_listings_screen.dart';
import '../widgets/superadmin_navigation_menu.dart';

class SuperAdminHome extends StatefulWidget {
  final UserSession userSession;

  const SuperAdminHome({super.key, required this.userSession});

  @override
  State<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends State<SuperAdminHome> {
  int _selectedPage = 1; // Start with Admin Dashboard selected

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              title: const Text(
                'UDD SuperAdmin',
                style: TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false, // Hide default drawer button
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer(); // Open drawer on tap
                    },
                  );
                },
              ),
            ),

      drawer: !isWideScreen
          ? SuperAdminNavigationMenu(
              selectedPage: _selectedPage,
              onPageSelected: (index) {
                setState(() => _selectedPage = index);
                Navigator.pop(context); // Close drawer after selection
              },
              userName: widget.userSession.email,
              isMobile: true,
            )
          : null,
      drawerEnableOpenDragGesture: false, // Disable drag to open

      body: Row(
        children: [
          // Show sidebar permanently on desktop
          if (isWideScreen)
            SuperAdminNavigationMenu(
              selectedPage: _selectedPage,
              onPageSelected: (index) => setState(() => _selectedPage = index),
              userName: widget.userSession.email,
              isMobile: false,
            ),

          // Main Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedPage == 0
                  ? SuperAdminListingsScreen(userSession: widget.userSession)
                  : SuperAdminDashboard(userSession: widget.userSession),
            ),
          ),
        ],
      ),
    );
  }
}
