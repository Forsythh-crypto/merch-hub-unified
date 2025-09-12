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

class AdminListingsScreen extends StatefulWidget {
  final UserSession userSession;

  const AdminListingsScreen({super.key, required this.userSession});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  List<Listing> _listings = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();

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
    _loadCategories();
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
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBadge(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // Refresh notification count when returning
              setState(() {});
            },
            child: const Icon(Icons.notifications),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/admin-add-listing');
                  if (result == true) {
                    _loadListings(); // Refresh listings after successful creation
                  }
                },
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminOrdersScreen(
                  userSession: widget.userSession,
                  showAppBar: false,
                ),
              ),
            ).then((_) {
              setState(() {
                _selectedIndex = 0;
              });
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          final listing = _listings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${listing.price.toStringAsFixed(2)}',
                        style: const TextStyle(
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
                      label: const Text('Approve'),
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
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteListing(listing),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
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
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
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

  // Removed _showAddListingDialog - now using separate AdminAddListingScreen
}
