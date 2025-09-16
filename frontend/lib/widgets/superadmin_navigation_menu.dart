import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminNavigationMenu extends StatefulWidget {
  final int selectedPage;
  final Function(int) onPageSelected;
  final String userName;
  final bool isMobile;

  const SuperAdminNavigationMenu({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
    required this.userName,
    this.isMobile = false,
  });

  @override
  State<SuperAdminNavigationMenu> createState() =>
      _SuperAdminNavigationMenuState();
}

class _SuperAdminNavigationMenuState extends State<SuperAdminNavigationMenu> {
  final bool _isAdminPanelExpanded = false;

  Widget _buildMenuItem(int index, IconData icon, String title, Color color) {
    final isSelected = widget.selectedPage == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? color : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        onTap: () {
          widget.onPageSelected(index);
          if (widget.isMobile) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuContent = Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF1E3A8A),
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'UDD SuperAdmin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                'IT Team Portal',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const Divider(),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildMenuItem(
                0,
                Icons.people,
                'User Management',
                const Color(0xFF1E3A8A),
              ),
              _buildMenuItem(
                1,
                Icons.school,
                'Department Management',
                const Color(0xFF1E3A8A),
              ),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.settings,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                  title: const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    _buildMenuItem(
                      2,
                      Icons.dashboard,
                      'Dashboard',
                      const Color(0xFF1E3A8A),
                    ),
                    _buildMenuItem(
                      3,
                      Icons.store,
                      'Products',
                      const Color(0xFF1E3A8A),
                    ),
                    _buildMenuItem(
                      4,
                      Icons.inventory,
                      'Inventory',
                      const Color(0xFF1E3A8A),
                    ),
                    _buildMenuItem(
                      5,
                      Icons.receipt_long,
                      'Orders',
                      const Color(0xFF1E3A8A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ), // Logout Button
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

    if (widget.isMobile) {
      return Drawer(child: menuContent);
    } else {
      return Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: menuContent,
      );
    }
  }
}
