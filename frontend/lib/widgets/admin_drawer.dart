import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedPage;
  final Function(int) onPageSelected;
  final String userName;
  final bool isMobile;

  const AdminDrawer({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.userName,
    this.isMobile = false,
  });

  Widget _buildDrawerItem(int index, IconData icon, String title, Color color) {
    final isSelected = selectedPage == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? color : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? color : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? color.withOpacity(0.1) : null,
      onTap: () => onPageSelected(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDrawer =
        Theme.of(context).platform != TargetPlatform.windows ||
        MediaQuery.of(context).size.width < 1200;

    Widget content = Column(
      children: [
        // Header
        if (isDrawer)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF1E3A8A),
                size: 30,
              ),
            ),
            accountName: const Text(
              'UDD SuperAdmin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userName),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF1E3A8A),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'UDD SuperAdmin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  userName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

        // Menu Items
        Expanded(
          child: ListView(
            children: [
              _buildDrawerItem(
                0,
                Icons.store,
                'Products',
                const Color(0xFF1E3A8A),
              ),
              _buildDrawerItem(
                1,
                Icons.shopping_cart,
                'Order Management',
                const Color(0xFF059669),
              ),
              _buildDrawerItem(
                2,
                Icons.local_offer,
                'Discount Codes',
                const Color(0xFFEF4444),
              ),
              _buildDrawerItem(
                3,
                Icons.admin_panel_settings,
                'Admin Dashboard',
                const Color(0xFF059669),
              ),
              _buildDrawerItem(
                4,
                Icons.people,
                'User Management',
                const Color(0xFFDC2626),
              ),
              _buildDrawerItem(
                5,
                Icons.school,
                'Department Management',
                const Color(0xFF7C3AED),
              ),
              _buildDrawerItem(
                6,
                Icons.analytics,
                'System Analytics',
                const Color(0xFFEA580C),
              ),
              _buildDrawerItem(
                7,
                Icons.settings,
                'System Settings',
                const Color(0xFF0891B2),
              ),
            ],
          ),
        ),

        // Logout Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
              
              if (shouldLogout == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ),
      ],
    );

    return isDrawer ? Drawer(child: content) : content;
  }
}
