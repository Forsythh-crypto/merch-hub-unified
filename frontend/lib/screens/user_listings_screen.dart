import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/admin_service.dart';
import '../config/app_config.dart';
import 'order_confirmation_screen.dart';

class UserListingsScreen extends StatefulWidget {
  final String? initialDepartment;

  const UserListingsScreen({super.key, this.initialDepartment});

  @override
  State<UserListingsScreen> createState() => _UserListingsScreenState();
}

class _UserListingsScreenState extends State<UserListingsScreen> {
  List<Listing> _listings = [];
  List<Listing> _newListings = []; // For new products section
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDepartment = 'All';
  List<String> _categories = ['All'];
  List<String> _departmentFilters = ['All'];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _departments = [
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

  bool _routeArgsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Handle both direct string and map arguments
    String? initialDepartment = widget.initialDepartment;
    if (initialDepartment == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        initialDepartment = args;
      } else if (args is Map<String, dynamic>) {
        initialDepartment = args['departmentName'] as String?;
      }
    }

    if (initialDepartment != null && _selectedDepartment == 'All') {
      setState(() {
        _selectedDepartment = initialDepartment!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getUserListings();

      // Extract unique categories and departments
      final categorySet = <String>{'All'};
      final departmentSet = <String>{'All'};
      for (final listing in listings) {
        if (listing.category?.name != null) {
          categorySet.add(listing.category!.name);
        }
        if (listing.department?.name != null) {
          departmentSet.add(listing.department!.name);
        }
      }

      setState(() {
        _listings = listings;
        _categories = categorySet.toList();
        _departmentFilters = departmentSet.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
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

      final matchesDepartment =
          _selectedDepartment == 'All' ||
          listing.department?.name == _selectedDepartment;

      return matchesSearch && matchesCategory && matchesDepartment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Available Products'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
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
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Department Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Department:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _departmentFilters.map((department) {
                          final isSelected = department == _selectedDepartment;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(department),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDepartment = department;
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: const Color(0xFF1E3A8A),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Active Filters Summary
                if (_selectedCategory != 'All' ||
                    _selectedDepartment != 'All' ||
                    _searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Filters:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _selectedDepartment = 'All';
                                  _searchQuery = '';
                                });
                                _searchController.clear();
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              Chip(
                                label: Text('Search: "$_searchQuery"'),
                                backgroundColor: const Color(
                                  0xFF1E3A8A,
                                ).withOpacity(0.2),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  _searchController.clear();
                                },
                              ),
                            if (_selectedCategory != 'All')
                              Chip(
                                label: Text('Category: $_selectedCategory'),
                                backgroundColor: const Color(
                                  0xFF1E3A8A,
                                ).withOpacity(0.2),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                  });
                                },
                              ),
                            if (_selectedDepartment != 'All')
                              Chip(
                                label: Text('Department: $_selectedDepartment'),
                                backgroundColor: const Color(
                                  0xFF1E3A8A,
                                ).withOpacity(0.2),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedDepartment = 'All';
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
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
                          'No products found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadListings,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: _filteredListings.length,
                      itemBuilder: (context, index) {
                        final listing = _filteredListings[index];
                        return _buildProductCard(listing);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Listing listing) {
    return GestureDetector(
      onTap: listing.stockQuantity > 0 ? () => _showOrderDialog(listing) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: listing.imagePath != null
                          ? Image.network(
                              Uri.encodeFull(
                                '${AppConfig.fileUrl(listing.imagePath)}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                              ),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                    ),

                    // Stock Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: listing.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          listing.stockQuantity > 0
                              ? 'In Stock'
                              : 'Out of Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Department and Category
                    Text(
                      '${listing.department?.name ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),

                    const Spacer(),

                    // Price and Size
                    Row(
                      children: [
                        Text(
                          '₱${listing.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const Spacer(),
                        if (listing.sizeVariants != null &&
                            listing.sizeVariants!.isNotEmpty) ...[
                          // Show available sizes for clothing
                          Wrap(
                            spacing: 4,
                            children: listing.sizeVariants!.take(3).map((
                              variant,
                            ) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: variant.stockQuantity > 0
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  variant.size,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: variant.stockQuantity > 0
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (listing.sizeVariants!.length > 3)
                            Text(
                              '+${listing.sizeVariants!.length - 3} more',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                        ] else if (listing.size != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              listing.size!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Pre-order Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: listing.stockQuantity > 0
                            ? () => _showOrderDialog(listing)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: listing.stockQuantity > 0
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: Text(
                          listing.stockQuantity > 0
                              ? 'Pre-order'
                              : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDialog(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(listing: listing),
      ),
    ).then((orderCreated) {
      if (orderCreated == true) {
        // Refresh listings if order was created
        _loadListings();
      }
    });
  }
}
