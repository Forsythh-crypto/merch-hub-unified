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
import 'edit_profile_screen.dart';

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
  
  // Search and Filter State
  String _searchQuery = '';
  String _selectedCategory = 'All';

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
      
      print('DEBUG: Loading listings for user role: ${widget.userSession.role}');
      print('DEBUG: User Department ID: ${widget.userSession.departmentId}');
      
      // Filter listings by admin's department for regular admins
      List<Listing> filteredListings = listings;
      if (widget.userSession.role == UserRole.admin) {
        if (widget.userSession.departmentId != null) {
          filteredListings = listings.where((listing) {
            final match = listing.departmentId == widget.userSession.departmentId;
             if (!match) {
               print('DEBUG: Filtering out listing ${listing.id} (Dept ID: ${listing.departmentId})');
             }
            return match;
          }).toList();
        } else {
          print('WARNING: Admin user has no department ID, falling back to name match');
          filteredListings = listings.where((listing) => 
            listing.department?.name == widget.userSession.departmentName
          ).toList();
        }
      }
      print('DEBUG: Filtered listings count: ${filteredListings.length}');



      if (!mounted) return;
      setState(() {
        _listings = filteredListings;
        _isLoading = false;
      });
    } catch (e) {
      // Error loading listings
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Listing> get _filteredListings {
    return _listings.where((listing) {
      final matchesSearch =
          listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (listing.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesCategory =
          _selectedCategory == 'All' ||
          listing.category?.name == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categoryNames {
    final names = <String>['All'];
    // Add categories from the loaded listings to ensure we only show relevant categories
    for (final listing in _listings) {
      if (listing.category?.name != null && !names.contains(listing.category!.name)) {
        names.add(listing.category!.name);
      }
    }
    // Also include categories from the _categories list if not already present
    for (final category in _categories) {
      if (!names.contains(category.name)) {
        names.add(category.name);
      }
    }
    return names;
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await AdminService.getAllCategories();
      final categories = categoriesData.map((c) => Category.fromJson(c)).toList();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Error loading categories
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error loading dashboard stats: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        toolbarHeight: 120,
        centerTitle: true,
        title: Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/logos/uddess.png',
            height: 100,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
                
                // Edit Profile
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            userData: {
                              'name': widget.userSession.name,
                              'email': widget.userSession.email,
                            },
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        // For AdminScreen, the user session is passed in via constructor.
                        // We need to fetch fresh data and update the local state or trigger a parent rebuild.
                        // Since this is a StatefulWidget, we should probably reload the user data here 
                        // but AdminListingsScreen functionality relies on widget.userSession. 
                        // A better approach for now might be to navigate to the splash screen or reload the app, 
                        // OR (better) fetch the updated user and create a new session object.
                        
                        final updatedUserData = await AuthService.getCurrentUser();
                        if (updatedUserData != null) {
                           // This is tricky because userSession is final in the widget.
                           // Ideally, we would reload the whole screen.
                           // For now, let's just trigger a reload of the main home screen logic by pushing
                           // replacement to the root wrapper or just popping everything.
                           // Actually, let's just accept that we might need to reload the whole app context.
                           // But to be user friendly, let's try to update locally if we can.
                           
                           // Since we can't easily mutate the widget.userSession, 
                           // let's navigate to the admin route again with the new arguments.
                           
                           final args = {
                              'userId': updatedUserData['id']?.toString() ?? '',
                              'name': updatedUserData['name'] ?? '',
                              'email': updatedUserData['email'] ?? '',
                              'role': updatedUserData['role'] ?? '',
                              'departmentId': updatedUserData['department_id'] is int ? updatedUserData['department_id'] : null,
                              'departmentName': updatedUserData['department_name'] ?? '',
                           };
                           
                           Navigator.pushReplacementNamed(context, '/admin', arguments: args);
                        }
                      }
                    },
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
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categoryNames.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredListings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No listings found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = _filteredListings[index];
                    return _buildListingCard(listing);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 120,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
             child: listing.images != null && listing.images!.isNotEmpty
                 ? ClipRRect(
                     borderRadius: const BorderRadius.only(
                       topLeft: Radius.circular(16),
                       bottomLeft: Radius.circular(16),
                     ),
                     child: PageView.builder(
                       itemCount: listing.images!.length,
                       itemBuilder: (context, index) {
                         final image = listing.images![index];
                         return Image.network(
                           Uri.encodeFull(AppConfig.fileUrl(image.imagePath)),
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) {
                             return const Icon(
                               Icons.image,
                               size: 50,
                               color: Colors.grey,
                             );
                           },
                         );
                       },
                     ),
                   )
                 : listing.imagePath != null
                     ? ClipRRect(
                         borderRadius: const BorderRadius.only(
                           topLeft: Radius.circular(16),
                           bottomLeft: Radius.circular(16),
                         ),
                         child: Image.network(
                           '${AppConfig.baseUrl}/api/files/${listing.imagePath}',
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) {
                             return const Icon(
                               Icons.image,
                               size: 50,
                               color: Colors.grey,
                             );
                           },
                         ),
                       )
                     : const Icon(Icons.image, size: 50, color: Colors.grey),
           ),

          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${listing.department?.name ?? 'N/A'} • ${listing.category?.name ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${listing.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Only show Approve button if Superadmin (though this screen is mostly for Admin)
                      if (listing.status == 'pending' &&
                          widget.userSession.role == UserRole.superAdmin) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveListing(listing),
                            icon: const Icon(Icons.check, size: 20),
                            label: const Text('Approve', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _editListing(listing),
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteListing(listing),
                          icon: const Icon(Icons.delete, size: 20),
                          label: const Text('Delete', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Denied'),
          content: Text('You can only edit listings from your own department. User: "$userDepartmentName", Listing: "${listing.department?.name}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
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
    // Only Super Admin can approve listings
    if (widget.userSession.role != UserRole.superAdmin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text('Only Super Admin can approve listings'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    try {
      await AdminService.approveListing(listing.id);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Listing approved successfully'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _loadListings();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to approve listing: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Listing deleted successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadListings();
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete listing: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
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
    final discountType = discountCode['type'];
    final discountValue = discountCode['value'];
    
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
                          () {
                            // Handle different data types for discount value
                            double? actualValue;
                            
                            if (discountValue is String) {
                              actualValue = double.tryParse(discountValue);
                            } else if (discountValue is num) {
                              actualValue = discountValue.toDouble();
                            }
                            
                            // Show the actual value even if it's 0, but handle null
                            if (actualValue == null) {
                              return 'Invalid discount value';
                            }
                            
                            return '${actualValue.toStringAsFixed(actualValue == actualValue.toInt() ? 0 : 1)}% off';
                          }(),
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
                if (discountCode['valid_from'] != null) ...[
                  Expanded(
                    child: _buildInfoChip(
                      'Valid From',
                      _formatDate(discountCode['valid_from']),
                      Icons.calendar_today,
                    ),
                  ),
                ],
                if (discountCode['valid_from'] != null && discountCode['valid_until'] != null)
                  const SizedBox(width: 8),
                if (discountCode['valid_until'] != null) ...[
                  Expanded(
                    child: _buildInfoChip(
                      'Valid Until',
                      _formatDate(discountCode['valid_until']),
                      Icons.event,
                    ),
                  ),
                ],
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Discount code created successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to create discount code: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
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

      final discountCodes = await AdminService().getDiscountCodes();
      
      setState(() {
        _discountCodes = discountCodes;
        _isLoading = false;
      });
    } catch (e) {
      // Error loading discount codes
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Discount code deleted successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete discount code: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
