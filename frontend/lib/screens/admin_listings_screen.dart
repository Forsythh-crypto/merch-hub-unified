import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../services/admin_service.dart';
import '../config/app_config.dart';
import 'admin_orders_screen.dart';

class AdminListingsScreen extends StatefulWidget {
  final UserSession userSession;

  const AdminListingsScreen({super.key, required this.userSession});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen>
    with SingleTickerProviderStateMixin {
  List<Listing> _listings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getAdminListings();

      print('📋 Loaded ${listings.length} listings for admin');
      for (final listing in listings) {
        print(
          '📋 Listing: ${listing.title} - Department: ${listing.department?.name} - Status: ${listing.status} - Stock: ${listing.stockQuantity}',
        );
        if (listing.sizeVariants != null && listing.sizeVariants!.isNotEmpty) {
          for (final variant in listing.sizeVariants!) {
            print('📋   Size ${variant.size}: ${variant.stockQuantity}');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading listings: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🔧 Building AdminListingsScreen with user: ${widget.userSession.name} (${widget.userSession.role}) - Department: ${widget.userSession.departmentName}',
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Admin Listings - ${widget.userSession.departmentName ?? "Unknown"}',
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              // Logout button row
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      widget.userSession.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldLogout == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('auth_token');
                          await prefs.remove('user_data');
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              // TabBar
              TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Manage Listings'),
                  Tab(text: 'Add New Listing'),
                  Tab(text: 'Manage Orders'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        children: [
          _buildManageListingsTab(),
          _buildAddListingTab(),
          // Orders tab (department-scoped by backend for admins)
          AdminOrdersScreen(userSession: widget.userSession, showAppBar: false),
        ],
      ),
    ),
    );
  }

  Widget _buildManageListingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No listings found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Create your first listing using the Add New tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _listings.length,
        itemBuilder: (context, index) {
          final listing = _listings[index];
          return _buildAdminListingCard(listing);
        },
      ),
    );
  }

  Widget _buildAdminListingCard(Listing listing) {
    return InkWell(
      onTap: () {
        print('🔘 Card tapped for: ${listing.title}');
        _editListing(listing);
      },
      borderRadius: BorderRadius.circular(12),
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
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: listing.imagePath != null
                          ? Image.network(
                              Uri.encodeFull(
                                '${AppConfig.baseUrl}/api/files/${listing.imagePath}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                              ),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
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

                    Text(
                      '${listing.category?.name ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),

                    const SizedBox(height: 4),

                    // Department indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.department?.name ?? 'Unknown Department',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Text(
                          '₱${listing.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Stock: ${listing.stockQuantity}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Action Buttons
                    Column(
                      children: [
                        // Edit button for all listings
                        Container(
                          width: double.infinity,
                          height: 45, // Slightly taller for better touch target
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ElevatedButton(
                            onPressed: () {
                              print(
                                '🔘 Edit button pressed for: ${listing.title}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Edit button pressed for: ${listing.title}',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              _editListing(listing);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              elevation:
                                  2, // Add some elevation for better visibility
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'EDIT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Approval button for pending listings
                        if (listing.status == 'pending')
                          Container(
                            width: double.infinity,
                            height: 35,
                            margin: const EdgeInsets.only(top: 4),
                            child: ElevatedButton(
                              onPressed: () => _approveListing(listing),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'APPROVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildAddListingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AddListingForm(
        onListingAdded: _loadListings,
        userSession: widget.userSession,
      ),
    );
  }

  Future<void> _editListing(Listing listing) async {
    print('🔧 _editListing called for: ${listing.title}');
    print('🔧 Current stock quantity: ${listing.stockQuantity}');
    print('🔧 Size variants: ${listing.sizeVariants?.length ?? 0}');
    if (listing.sizeVariants != null) {
      for (final variant in listing.sizeVariants!) {
        print('🔧 Size ${variant.size}: ${variant.stockQuantity}');
      }
    }

    // Navigate to edit screen or show edit dialog
    // For now, show a simple edit dialog
    final titleController = TextEditingController(text: listing.title);
    final descriptionController = TextEditingController(
      text: listing.description,
    );
    final priceController = TextEditingController(
      text: listing.price.toString(),
    );
    final stockController = TextEditingController(
      text: listing.stockQuantity.toString(),
    );

    // Check if this is a clothing item with size variants
    final hasSizeVariants =
        listing.sizeVariants != null && listing.sizeVariants!.isNotEmpty;
    final isClothing =
        listing.category?.name.toLowerCase().contains('clothing') ?? false;

    // Per-size stock controllers for clothing
    final Map<String, TextEditingController> sizeQtyControllers = {
      'XS': TextEditingController(),
      'S': TextEditingController(),
      'M': TextEditingController(),
      'L': TextEditingController(),
      'XL': TextEditingController(),
      'XXL': TextEditingController(),
    };

    // Initialize size controllers with existing data
    if (hasSizeVariants && listing.sizeVariants != null) {
      for (final variant in listing.sizeVariants!) {
        if (sizeQtyControllers.containsKey(variant.size)) {
          sizeQtyControllers[variant.size]!.text = variant.stockQuantity
              .toString();
        }
      }
    } else if (isClothing) {
      // If it's clothing but no size variants, distribute the total stock across sizes
      final totalStock = listing.stockQuantity;
      final defaultStock = totalStock > 0 ? (totalStock / 6).round() : 0;

      for (final controller in sizeQtyControllers.values) {
        controller.text = defaultStock.toString();
      }

      // Put remaining stock in the first size (M)
      if (totalStock > 0) {
        final remaining = totalStock - (defaultStock * 6);
        if (remaining > 0) {
          sizeQtyControllers['M']!.text = (defaultStock + remaining).toString();
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Listing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (₱)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isClothing && !hasSizeVariants)
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                  ],
                ),
                if (isClothing || hasSizeVariants) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Stock per Size:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sizeQtyControllers.entries.map((entry) {
                      return SizedBox(
                        width: 100,
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: entry.key,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title is required'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Update basic info
                  final success = await AdminService.updateListing(
                    listing.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    price:
                        double.tryParse(priceController.text.trim()) ??
                        listing.price,
                  );

                  if (success) {
                    // Update size variants if it's clothing
                    if (isClothing || hasSizeVariants) {
                      final sizeVariants = <Map<String, dynamic>>[];
                      for (final entry in sizeQtyControllers.entries) {
                        final stock = int.tryParse(entry.value.text.trim());
                        if (stock != null && stock >= 0) {
                          sizeVariants.add({
                            'size': entry.key,
                            'stock_quantity': stock,
                          });
                        }
                      }

                      if (sizeVariants.isNotEmpty) {
                        await AdminService.updateListingSizeVariants(
                          listing.id,
                          sizeVariants,
                        );
                      }
                    } else {
                      // Update single stock quantity for non-clothing
                      final newStock = int.tryParse(stockController.text);
                      if (newStock != null) {
                        // Update the listing with the new stock quantity
                        await AdminService.updateListing(
                          listing.id,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          price:
                              double.tryParse(priceController.text.trim()) ??
                              listing.price,
                          stockQuantity: newStock,
                        );
                      }
                    }

                    // Close dialog and refresh
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    await _loadListings(); // Wait for the refresh to complete

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update listing'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error updating listing: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update listing'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Approve listing method
  Future<void> _approveListing(Listing listing) async {
    try {
      print('🔄 Approving listing: ${listing.title} (ID: ${listing.id})');

      final success = await AdminService.approveListing(listing.id);

      if (success) {
        print('✅ Listing approved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing "${listing.title}" approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the data to show updated status
        _loadListings();
      } else {
        print('❌ Failed to approve listing');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error approving listing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _AddListingForm extends StatefulWidget {
  final Future<void> Function() onListingAdded;
  final UserSession userSession;

  const _AddListingForm({
    required this.onListingAdded,
    required this.userSession,
  });

  @override
  State<_AddListingForm> createState() => _AddListingFormState();
}

class _AddListingFormState extends State<_AddListingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _sizeController = TextEditingController();
  final Map<String, TextEditingController> _sizeQtyControllers = {
    'XS': TextEditingController(text: ''),
    'S': TextEditingController(text: ''),
    'M': TextEditingController(text: ''),
    'L': TextEditingController(text: ''),
    'XL': TextEditingController(text: ''),
    'XXL': TextEditingController(text: ''),
  };

  int? _selectedCategoryId;
  int? _selectedDepartmentId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  bool get _isClothingSelected {
    if (_selectedCategoryId == null) return false;
    final match = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {},
    );
    final name = (match['name'] ?? '').toString();
    final isClothing =
        name.toLowerCase().contains('clothing') ||
        name.toLowerCase() == 'clothes';
    print('Category: $name, isClothing: $isClothing');
    return isClothing;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDepartments();

    // Pre-select user's department for non-superadmins
    if (!widget.userSession.isSuperAdmin) {
      _selectedDepartmentId = widget.userSession.departmentId;
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      print('Loading categories with token: ${token?.substring(0, 20)}...');

      final response = await http.get(
        AppConfig.api('categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Categories response status: ${response.statusCode}');
      print('Categories response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['categories']);
          _isLoading = false;
        });
        print(
          'Loaded ${_categories.length} categories: ${_categories.map((c) => c['name']).toList()}',
        );
      } else {
        print('Failed to load categories: ${response.statusCode}');
        // Fallback to default categories
        setState(() {
          _categories = [
            {'id': 1, 'name': 'Clothing'},
            {'id': 2, 'name': 'Accessories'},
            {'id': 3, 'name': 'Supplies'},
            {'id': 4, 'name': 'Tech'},
          ];
          _isLoading = false;
        });
        print(
          'Using fallback categories: ${_categories.map((c) => c['name']).toList()}',
        );
      }
    } catch (e) {
      print('Error loading categories: $e');
      // Fallback to default categories
      setState(() {
        _categories = [
          {'id': 1, 'name': 'Clothing'},
          {'id': 2, 'name': 'Accessories'},
          {'id': 3, 'name': 'Supplies'},
          {'id': 4, 'name': 'Tech'},
        ];
        _isLoading = false;
      });
      print(
        'Using fallback categories due to error: ${_categories.map((c) => c['name']).toList()}',
      );
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        AppConfig.api('departments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data['departments']);
        });
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _getToken();

      if (_isClothingSelected) {
        // Collect per-size stocks
        final entries = _sizeQtyControllers.entries
            .map((e) => MapEntry(e.key, int.tryParse(e.value.text.trim())))
            .where((e) => (e.value ?? 0) > 0)
            .toList();

        if (entries.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter stock for at least one size'),
            ),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        // Create single listing with size variants
        final request = http.MultipartRequest(
          'POST',
          AppConfig.api('listings'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['title'] = _titleController.text;
        request.fields['description'] = _descriptionController.text;
        request.fields['price'] = _priceController.text;
        request.fields['category_id'] = _selectedCategoryId.toString();
        request.fields['department_id'] = _selectedDepartmentId.toString();

        // Add size variants as JSON
        final sizeVariants = <Map<String, dynamic>>[];
        for (final entry in entries) {
          sizeVariants.add({'size': entry.key, 'stock_quantity': entry.value});
        }
        final sizeVariantsJson = jsonEncode(sizeVariants);
        print('Size variants JSON: $sizeVariantsJson');
        request.fields['size_variants'] = sizeVariantsJson;

        // Add image if selected
        if (_selectedImage != null) {
          final imageStream = http.ByteStream(_selectedImage!.openRead());
          final imageLength = await _selectedImage!.length();
          final multipartFile = http.MultipartFile(
            'image',
            imageStream,
            imageLength,
            filename: _selectedImage!.path.split('/').last,
          );
          request.files.add(multipartFile);
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        print('Response status: ${response.statusCode}');
        print('Response body: $responseBody');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            _clearForm();
            // Success dialog with navigation
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Listing Created'),
                content: const Text('The listing was created successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // Stay on add tab to add another
                    },
                    child: const Text('Add Another'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      // Navigate to Manage Listings and refresh
                      final controller = DefaultTabController.of(context);
                      controller?.animateTo(0);
                      await widget.onListingAdded();
                    },
                    child: const Text('View Listings'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create listing')),
            );
          }
        }
      } else {
        // Non-clothing: single listing
        final request = http.MultipartRequest(
          'POST',
          AppConfig.api('listings'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['title'] = _titleController.text;
        request.fields['description'] = _descriptionController.text;
        request.fields['price'] = _priceController.text;
        request.fields['stock_quantity'] = _stockController.text;
        request.fields['category_id'] = _selectedCategoryId.toString();
        request.fields['department_id'] = _selectedDepartmentId.toString();
        if (_sizeController.text.isNotEmpty) {
          request.fields['size'] = _sizeController.text;
        }

        // Add image if selected
        if (_selectedImage != null) {
          final imageStream = http.ByteStream(_selectedImage!.openRead());
          final imageLength = await _selectedImage!.length();
          final multipartFile = http.MultipartFile(
            'image',
            imageStream,
            imageLength,
            filename: _selectedImage!.path.split('/').last,
          );
          request.files.add(multipartFile);
        }

        final response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            _clearForm();
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Listing Created'),
                content: const Text('The listing was created successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Add Another'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final controller = DefaultTabController.of(context);
                      controller?.animateTo(0);
                      await widget.onListingAdded();
                    },
                    child: const Text('View Listings'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create listing')),
            );
          }
        }
      }
    } catch (e) {
      print('Error creating listing: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error creating listing')));
      }
    }

    setState(() => _isSubmitting = false);
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.text = '1';
    _sizeController.clear();
    for (final c in _sizeQtyControllers.values) {
      c.clear();
    }
    setState(() {
      _selectedCategoryId = null;
      _selectedDepartmentId = null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building form - isClothingSelected: $_isClothingSelected');
    print('Categories loaded: ${_categories.length}');
    print('Categories: ${_categories.map((c) => c['name']).toList()}');
    print('Departments loaded: ${_departments.length}');

    // Show loading indicator if categories are still loading
    if (_isLoading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Listing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add image',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Product Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Category Dropdown
          if (_categories.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Loading categories...',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ] else ...[
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category['id'],
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 16),

          // Department Selection
          if (widget.userSession.isSuperAdmin) ...[
            // Department Dropdown for SuperAdmin
            DropdownButtonFormField<int>(
              value: _selectedDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              items: _departments.map((department) {
                return DropdownMenuItem<int>(
                  value: department['id'],
                  child: Text(department['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a department';
                }
                return null;
              },
            ),
          ] else ...[
            // Read-only department field for regular admins
            TextFormField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Department',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              initialValue:
                  widget.userSession.departmentName ??
                  'Unknown Department (Please log out and log back in)',
            ),
          ],

          const SizedBox(height: 16),

          // Price
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price (₱)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a price';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid price';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Stock inputs
          if (_isClothingSelected) ...[
            const Text(
              'Per-size stock (Clothing)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _sizeQtyControllers.keys.map((size) {
                return SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _sizeQtyControllers[size],
                    decoration: InputDecoration(
                      labelText: size,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid quantity';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 16),

          // Size (optional for non-clothing)
          if (!_isClothingSelected)
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., S, M, L, XL',
              ),
            ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitListing,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Listing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _sizeController.dispose();
    super.dispose();
  }
}
