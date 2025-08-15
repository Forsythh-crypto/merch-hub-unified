import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/admin_service.dart';
import '../services/auth_services.dart';
import '../screens/config/app_config.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Listing> _listings = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'School of Information Technology Education',
      'logo': 'assets/logos/site.png',
      'color': const Color(0xFF6B7280), // Gray
    },
    {
      'name': 'School of Business Administration',
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
      final listings = await AdminService.getUserListings();
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UDD MERCH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              // TODO: Implement profile
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // TODO: Implement wishlist
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Implement cart
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/welcome');
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
                      height: 300,
                      decoration: const BoxDecoration(color: Color(0xFFE6F3FF)),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 200,
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'NEW ARRIVAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'UDD MERCH',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                const Text(
                                  'Show your school pride',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Navigate to all products
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text('SHOP NOW'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // New Products Section
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
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/user-listings',
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
                              itemCount: _listings.take(5).length,
                              itemBuilder: (context, index) {
                                final listing = _listings[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: listing.imagePath != null
                                              ? Image.network(
                                                  Uri.encodeFull(
                                                    '${AppConfig.baseUrl}/api/files/${listing.imagePath}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                                                  ),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                )
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image,
                                                  ),
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                listing.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₱${listing.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF1E3A8A),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
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
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final department = _departments[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/user-listings',
                                    arguments: {
                                      'departmentName': department['name'],
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: department['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        department['logo'],
                                        height: 60,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          department['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
}
