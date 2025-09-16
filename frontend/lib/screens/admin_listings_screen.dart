import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import '../widgets/notification_badge.dart';
import '../services/auth_services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'admin_orders_screen.dart';
import 'notifications_screen.dart';
import 'edit_listing_screen.dart';
import 'admin_add_listing_screen.dart';
import 'admin_discount_codes_screen.dart';

class AdminListingsScreen extends StatefulWidget {
  final UserSession userSession;

  const AdminListingsScreen({super.key, required this.userSession});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  List<Listing> _listings = [];
  List<Category> _categories = [];
  List<Map<String, dynamic>> _discountCodes = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _notificationBadgeKey = GlobalKey();
  Map<String, dynamic> _dashboardStats = {
    'totalListings': 0,
    'totalOrders': 0,
    'pendingOrders': 0,
    'completedOrders': 0,
  };

  // Helper function to get abbreviated admin title
  String _getAdminTitle(String? departmentName) {
    if (departmentName == null) return 'ADMIN';
    
    switch (departmentName.toLowerCase()) {
      case 'school of information technology education':
        return 'SITE ADMIN';
      case 'school of business and accountancy':
        return 'SBA ADMIN';
      case 'school of criminology':
        return 'SOC ADMIN';
      case 'school of engineering':
        return 'SOE ADMIN';
      case 'school of health sciences':
        return 'SOHS ADMIN';
      case 'school of humanities':
        return 'SOH ADMIN';
      case 'school of international hospitality management':
        return 'SIHM ADMIN';
      case 'school of teacher education':
        return 'STE ADMIN';
      default:
        return 'ADMIN';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadDashboardStats();
    _loadDiscountCodes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getAdminListings();
      
      // Filter listings by admin's department for regular admins
      List<Listing> filteredListings = listings;
      if (widget.userSession.role == UserRole.admin) {
        filteredListings = listings.where((listing) => 
          listing.department?.name == widget.userSession.departmentName
        ).toList();
      }



      if (!mounted) return;
      setState(() {
        _listings = filteredListings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await AdminService.getAllCategories();
      final categories = categoriesData.map((c) => Category.fromJson(c)).toList();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('❌ Error loading categories: $e');
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Load listings count for this department
      final listingsResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/admin/listings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Load orders count for this department
      final ordersResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/admin/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (listingsResponse.statusCode == 200 && ordersResponse.statusCode == 200) {
        final listingsData = json.decode(listingsResponse.body);
        final ordersData = json.decode(ordersResponse.body);
        
        final orders = ordersData['orders'] as List;
        final pendingOrders = orders.where((order) => order['status'] == 'pending').length;
        final completedOrders = orders.where((order) => order['status'] == 'completed').length;

        setState(() {
          _dashboardStats = {
            'totalListings': listingsData['listings']?.length ?? 0,
            'totalOrders': orders.length,
            'pendingOrders': pendingOrders,
            'completedOrders': completedOrders,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🔧 Building AdminListingsScreen with user: ${widget.userSession.name} (${widget.userSession.role}) - Department: ${widget.userSession.departmentName}',
    );
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getAdminTitle(widget.userSession.departmentName),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NotificationBadge(
              key: _notificationBadgeKey,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                // Refresh notification count when returning
                (_notificationBadgeKey.currentState as dynamic)?.refreshCount();
              },
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildCurrentBody(),
      floatingActionButton: _selectedIndex == 4 ? FloatingActionButton(
        onPressed: _showCreateDiscountCodeDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getAdminTitle(widget.userSession.departmentName),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.userSession.name,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.dashboard,
                      color: _selectedIndex == 0 ? const Color(0xFF1E3A8A) : Colors.grey[600],
                    ),
                    title: Text(
                      'Dashboard',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _selectedIndex == 0 ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        fontWeight: _selectedIndex == 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.inventory,
                      color: _selectedIndex == 1 ? const Color(0xFF1E3A8A) : Colors.grey[600],
                    ),
                    title: Text(
                      'Listings',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _selectedIndex == 1 ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        fontWeight: _selectedIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.add_box,
                      color: _selectedIndex == 2 ? const Color(0xFF1E3A8A) : Colors.grey[600],
                    ),
                    title: Text(
                      'Add Listing',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _selectedIndex == 2 ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        fontWeight: _selectedIndex == 2 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3 ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.shopping_cart,
                      color: _selectedIndex == 3 ? const Color(0xFF1E3A8A) : Colors.grey[600],
                    ),
                    title: Text(
                      'Orders',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _selectedIndex == 3 ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        fontWeight: _selectedIndex == 3 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 4 ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_offer,
                      color: _selectedIndex == 4 ? const Color(0xFF1E3A8A) : Colors.grey[600],
                    ),
                    title: Text(
                      'Discount Codes',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _selectedIndex == 4 ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        fontWeight: _selectedIndex == 4 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      Navigator.pop(context);
                      _loadDiscountCodes();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Logout
          const Divider(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'Montserrat'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontFamily: 'Montserrat'),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardBody();
      case 1:
        return _buildListingsBody();
      case 2:
        return AdminAddListingScreen(
          showAppBar: false,
          userSession: {
            'userId': widget.userSession.userId,
            'name': widget.userSession.name,
            'email': widget.userSession.email,
            'role': widget.userSession.role.toString().split('.').last,
            'departmentId': widget.userSession.departmentId,
            'departmentName': widget.userSession.departmentName,
          },
          onListingCreated: () {
            _loadListings();
            setState(() {
              _selectedIndex = 1;
            });
          },
        );
      case 3:
        return AdminOrdersScreen(userSession: widget.userSession, showAppBar: false);
      case 4:
        return _buildDiscountCodesBody();
      default:
        return _buildDashboardBody();
    }
  }

  Widget _buildListingsBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No listings found',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _listings.length,
          itemBuilder: (context, index) {
            final listing = _listings[index];
            return _buildListingCard(listing);
          },
        ),
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${listing.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(listing.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing.status.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              listing.description ?? '',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${listing.stockQuantity}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (listing.category != null) ...[
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                   const SizedBox(width: 4),
                   Text(
                     listing.category!.name,
                     style: TextStyle(
                       fontFamily: 'Montserrat',
                       color: Colors.grey[600],
                     ),
                   ),
                 ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (listing.status == 'pending' &&
                    widget.userSession.role == UserRole.superAdmin)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveListing(listing),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontFamily: 'Montserrat'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (listing.status == 'pending' &&
                    widget.userSession.role == UserRole.superAdmin)
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editListing(listing),
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteListing(listing),
                    icon: const Icon(Icons.delete),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _editListing(Listing listing) {
    // Check if admin can edit this listing (same department)
    final userRole = widget.userSession.role;
    final userDepartmentName = widget.userSession.departmentName;
    

    
    if (userRole != UserRole.superAdmin && listing.department?.name != userDepartmentName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only edit listings from your own department. User: "$userDepartmentName", Listing: "${listing.department?.name}"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListingScreen(
          listing: listing,
          userSession: {
            'userId': widget.userSession.userId,
            'name': widget.userSession.name,
            'email': widget.userSession.email,
            'role': widget.userSession.role.toString().split('.').last,
            'departmentId': widget.userSession.departmentId,
            'departmentName': widget.userSession.departmentName,
          },
          categories: _categories,
          onListingUpdated: _loadListings,
        ),
      ),
    );
  }

  Future<void> _approveListing(Listing listing) async {
    // Only superadmins can approve listings
    if (widget.userSession.role != UserRole.superAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only superadmins can approve listings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      await AdminService.approveListing(listing.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadListings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteListing(Listing listing) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Listing',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        content: Text(
          'Are you sure you want to delete "${listing.title}"?',
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await AdminService.deleteListing(listing.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadListings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDashboardBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Listings',
                  _dashboardStats['totalListings'].toString(),
                  Icons.inventory,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Orders',
                  _dashboardStats['totalOrders'].toString(),
                  Icons.shopping_cart,
                  Colors.green,
                ),
                _buildStatCard(
                  'Pending Orders',
                  _dashboardStats['pendingOrders'].toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed Orders',
                  _dashboardStats['completedOrders'].toString(),
                  Icons.check_circle,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Removed _showAddListingDialog - now using separate AdminAddListingScreen

  Widget _buildDiscountCodesBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDiscountCodes,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_discountCodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No discount codes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first discount code using the + button',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Codes (${_discountCodes.length})',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _discountCodes.length,
              itemBuilder: (context, index) {
                final discountCode = _discountCodes[index];
                return _buildDiscountCodeCard(discountCode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCodeCard(Map<String, dynamic> discountCode) {
    final isActive = discountCode['is_active'] == true;
    final usageCount = discountCode['used_count'] ?? 0;
    final maxUsage = discountCode['max_usage'];
    final discountType = discountCode['discount_type'];
    final discountValue = discountCode['discount_value'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            discountCode['code'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discountType == 'percentage'
                            ? '${discountValue}% off'
                            : '₱${discountValue} off',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (discountCode['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          discountCode['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteDiscountCode(discountCode['id']);
                    }
                  },
                  itemBuilder: (context) => [

                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Usage',
                    maxUsage != null ? '$usageCount/$maxUsage' : '$usageCount',
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 8),
                if (discountCode['valid_from'] != null)
                  Expanded(
                    child: _buildInfoChip(
                      'Valid From',
                      _formatDate(discountCode['valid_from']),
                      Icons.calendar_today,
                    ),
                  ),
                const SizedBox(width: 8),
                if (discountCode['valid_until'] != null)
                  Expanded(
                    child: _buildInfoChip(
                      'Valid Until',
                      _formatDate(discountCode['valid_until']),
                      Icons.event,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _showCreateDiscountCodeDialog() async {
    // Load departments for the dialog
    List<Map<String, dynamic>> departments = [];
    if (widget.userSession.isSuperAdmin) {
      try {
        departments = await AdminService().getDepartments();
      } catch (e) {
        print('Failed to load departments: $e');
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateDiscountCodeDialog(
        departments: departments,
        userSession: widget.userSession,
      ),
    );

    if (result != null) {
      try {
        await AdminService().createDiscountCode(result);
        await _loadDiscountCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount code created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create discount code: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadDiscountCodes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Loading discount codes...');
      final discountCodes = await AdminService().getDiscountCodes();
      print('✅ Loaded ${discountCodes.length} discount codes');
      
      setState(() {
        _discountCodes = discountCodes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading discount codes: $e');
      setState(() {
        _error = 'Failed to load discount codes: $e';
        _isLoading = false;
      });
    }
  }



  Future<void> _deleteDiscountCode(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount Code'),
        content: const Text('Are you sure you want to delete this discount code? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService().deleteDiscountCode(id);
        await _loadDiscountCodes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discount code deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete discount code: $e')),
          );
        }
      }
    }
  }
}
