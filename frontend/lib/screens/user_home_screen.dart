import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';
import '../services/admin_service.dart';
import '../services/auth_services.dart';
import '../widgets/notification_badge.dart';
import '../config/app_config.dart';
import 'user_orders_screen.dart';
import 'order_confirmation_screen.dart';
import 'notifications_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Listing> _listings = [];
  List<Listing> _officialMerchListings = [];
  List<Listing> _departmentListings = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'School of Information Technology Education',
      'logo': 'assets/logos/site.png',
      'color': const Color(0xFF6B7280), // Gray
    },
    {
      'name': 'School of Business and Accountancy',
      'logo': 'assets/logos/sba.png',
      'color': const Color(0xFFF59E0B), // Yellow
    },
    {
      'name': 'School of Criminology',
      'logo': 'assets/logos/soc.png',
      'color': const Color(0xFF800000), // Maroon
    },
    {
      'name': 'School of Engineering',
      'logo': 'assets/logos/soe.png',
      'color': const Color(0xFFEA580C), // Orange
    },
    {
      'name': 'School of Teacher Education',
      'logo': 'assets/logos/ste.png',
      'color': const Color(0xFF2563EB), // Blue
    },
    {
      'name': 'School of Humanities',
      'logo': 'assets/logos/soh.png',
      'color': const Color(0xFF7C3AED), // Purple
    },
    {
      'name': 'School of Health Sciences',
      'logo': 'assets/logos/sohs.png',
      'color': const Color(0xFF059669), // Green
    },
    {
      'name': 'School of International Hospitality Management',
      'logo': 'assets/logos/sihm.png',
      'color': const Color(0xFFDC2626), // Red
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getApprovedListings();
      
      final officialMerch = listings
          .where(
            (listing) => listing.department?.name == 'Official UDD Merch',
          )
          .toList();
      
      final departmentListings = listings
          .where(
            (listing) => listing.department?.name != 'Official UDD Merch',
          )
          .toList();
      
      setState(() {
        _listings = listings;
        _officialMerchListings = officialMerch;
        _departmentListings = departmentListings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logos/uddess_black.png',
                  height: 10,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'UDD ESSENTIALS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'Montserrat',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your One-Stop Shop for UDD Merchandise',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF1E3A8A)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
            title: const Text('Browse Products'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/user-listings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E3A8A)),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserOrdersScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              _showAboutUsDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: Color(0xFF1E3A8A)),
            title: const Text('Contact Us'),
            onTap: () {
              Navigator.pop(context);
              _showContactUsDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
               Navigator.pop(context);
               // Clear user session and navigate to welcome
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear();
               if (mounted) {
                 Navigator.of(context).pushReplacementNamed('/welcome');
               }
             },
          ),
        ],
      ),
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Image.asset(
                  'assets/logos/uddess_black.png',
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'UDD ESSENTIALS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'Montserrat',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'About UDD Essentials',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'UDD Essentials is your premier destination for authentic University of Dagupan merchandise. We provide a comprehensive platform that connects students, faculty, and alumni with official UDD products and department-specific merchandise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                _buildAboutFeature(
                  icon: Icons.verified_user,
                  title: 'Authentic Products',
                  description: 'Every item in our catalog is officially licensed and approved by the University of Dagupan. We guarantee the authenticity and quality of all merchandise, ensuring you receive genuine UDD products that represent your school pride with excellence.',
                ),
                const SizedBox(height: 16),
                _buildAboutFeature(
                  icon: Icons.local_shipping,
                  title: 'Easy Pickup',
                  description: 'Our convenient pickup system allows you to collect your orders at multiple locations across the UDD campus. With flexible pickup hours and strategically placed collection points, getting your merchandise has never been more convenient for busy students and staff.',
                ),
                const SizedBox(height: 16),
                _buildAboutFeature(
                  icon: Icons.security,
                  title: 'Secure Payments',
                  description: 'We prioritize your financial security with our robust payment system. Our platform uses industry-standard encryption and secure payment gateways to protect your personal and financial information, ensuring safe and reliable transactions every time.',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.contact_support,
                    size: 60,
                    color: Color(0xFF1E3A8A),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Get in touch with us for any questions, concerns, or feedback about UDD Essentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                _buildContactItem(
                  icon: Icons.location_on,
                  title: 'Address',
                  content: 'University of Dagupan\nArellano Street, Dagupan City\nPangasinan, Philippines',
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  icon: Icons.phone,
                  title: 'Phone',
                  content: '+63 75 522 3922\n+63 75 515 1143',
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  content: 'info@ud.edu.ph\nregistrar@ud.edu.ph',
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  icon: Icons.schedule,
                  title: 'Business Hours',
                  content: 'Monday - Friday: 8:00 AM - 5:00 PM\nSaturday: 8:00 AM - 12:00 PM\nSunday: Closed',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Listing listing) {
    return InkWell(
      onTap: () {
        // Navigate directly to order confirmation screen to show product details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(listing: listing),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: listing.imagePath != null
                    ? Image.network(
                        Uri.encodeFull(
                          '${AppConfig.baseUrl}/api/files/${listing.imagePath}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                        ),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.department?.name ?? 'Unknown Department',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: NotificationBadge(
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
              child: const Icon(Icons.notifications, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(context, '/user-listings');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 1.0, right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserOrdersScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadListings,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Banner Section
                    Container(
                      width: double.infinity,
                      height: 350,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F3FF),
                        image: DecorationImage(
                          image: AssetImage('assets/images/hero_bg.png'),
                          fit: BoxFit.cover,
                          opacity: 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Very subtle blur effect for background
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Image.asset(
                                        'assets/logos/uddess_black.png',
                                        height: 180,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Text(
                                            'UDD ESSENTIALS',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/user-listings',
                                          arguments: 'Shop',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 18,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                           borderRadius: BorderRadius.zero,
                                         ),
                                      ),
                                      child: const Text(
                                        'SHOP NOW',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Official UDD Merch Section
                    if (_officialMerchListings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'OFFICIAL UDD MERCH',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/user-listings',
                                      arguments: 'Official UDD Merch',
                                    );
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _officialMerchListings
                                    .take(5)
                                    .length,
                                itemBuilder: (context, index) {
                                  final listing = _officialMerchListings[index];
                                  return _buildProductCard(listing);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // New Products Section (Department Products)
                    if (_departmentListings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NEW PRODUCTS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/user-listings',
                                      arguments: 'All',
                                    );
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(color: Color(0xFF1E3A8A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _departmentListings.take(5).length,
                                itemBuilder: (context, index) {
                                  final listing = _departmentListings[index];
                                  return _buildProductCard(listing);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Departments Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BROWSE BY DEPARTMENT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                ),
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final department = _departments[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/user-listings',
                                    arguments: department['name'],
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Large Logo
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(60),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: department['logo'] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(60),
                                              child: Image.asset(
                                                department['logo'],
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                      return Container(
                                                        width: 120,
                                                        height: 120,
                                                        decoration: BoxDecoration(
                                                          color: department['color'],
                                                          borderRadius:
                                                              BorderRadius.circular(60),
                                                        ),
                                                        child: Icon(
                                                          Icons.school,
                                                          color: Colors.white,
                                                          size: 50,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            )
                                          : Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: department['color'],
                                                borderRadius:
                                                    BorderRadius.circular(60),
                                              ),
                                              child: Icon(
                                                Icons.school,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Label below logo
                                    Text(
                                      department['name'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Add bottom padding to prevent overflow
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

    );
  }
}
