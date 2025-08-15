import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../services/admin_service.dart';
import '../screens/config/app_config.dart';

class AdminListingsScreen extends StatefulWidget {
  final UserSession userSession;

  const AdminListingsScreen({super.key, required this.userSession});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Listing> _listings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final listings = await AdminService.getAdminListings();

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
    print(
      '🔧 Building AdminListingsScreen with user: ${widget.userSession.name}',
    );
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Listings'),
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
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Manage Listings'),
                  Tab(text: 'Add New Listing'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildManageListingsTab(), _buildAddListingTab()],
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
    return Container(
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
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),

                  // Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Action Buttons (only for pending items)
                  if (listing.status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approveListing(listing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _deleteListing(listing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontSize: 10),
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

  Widget _buildAddListingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _AddListingForm(
        onListingAdded: _loadListings,
        userSession: widget.userSession,
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

  Future<void> _approveListing(Listing listing) async {
    final success = await AdminService.approveListing(listing.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${listing.title} approved successfully')),
      );
      _loadListings(); // Refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve listing')),
      );
    }
  }

  Future<void> _deleteListing(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminService.deleteListing(listing.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${listing.title} deleted successfully')),
        );
        _loadListings(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete listing')),
        );
      }
    }
  }
}

class _AddListingForm extends StatefulWidget {
  final VoidCallback onListingAdded;
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
    return name.toLowerCase().contains('clothing') ||
        name.toLowerCase() == 'clothes';
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
      final response = await http.get(
        AppConfig.api('categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['categories']);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
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

  Future<void> _pickImage() async {
    // Image picker functionality can be implemented later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker not implemented yet')),
    );
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

        int successCount = 0;
        for (final entry in entries) {
          final request = http.MultipartRequest(
            'POST',
            AppConfig.api('listings'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.fields['title'] = _titleController.text;
          request.fields['description'] = _descriptionController.text;
          request.fields['price'] = _priceController.text;
          request.fields['stock_quantity'] = (entry.value!).toString();
          request.fields['category_id'] = _selectedCategoryId.toString();
          request.fields['department_id'] = _selectedDepartmentId.toString();
          request.fields['size'] = entry.key;

          final resp = await request.send();
          if (resp.statusCode == 200 || resp.statusCode == 201) {
            successCount += 1;
          }
        }

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created $successCount size variant(s)')),
          );
          _clearForm();
          widget.onListingAdded();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create size variants')),
          );
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
        final response = await request.send();
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing created successfully')),
          );
          _clearForm();
          widget.onListingAdded();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create listing')),
          );
        }
      }
    } catch (e) {
      print('Error creating listing: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error creating listing')));
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
              child: const Column(
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
                  widget.userSession.departmentName ?? 'Unknown Department',
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
