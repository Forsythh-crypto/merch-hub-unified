import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../config/app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'superadmin_edit_listing_screen.dart';

class ProductsScreen extends StatefulWidget {
  final UserSession userSession;

  const ProductsScreen({Key? key, required this.userSession}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Listing> _listings = [];
  List<Listing> _filteredListings = [];
  bool _isLoading = true;
  
  // Search and filter variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';
  String _selectedCategoryFilter = 'all';
  
  // Variables for the add product form
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  String selectedStatus = 'pending';
  int? selectedCategoryId;
  int? selectedDepartmentId;
  List<File> selectedImages = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> departments = [];
  
  // Size variants for clothing items - using predefined sizes like edit screen
  final Map<String, TextEditingController> _sizeQtyControllers = {
    'XS': TextEditingController(text: '0'),
    'S': TextEditingController(text: '0'),
    'M': TextEditingController(text: '0'),
    'L': TextEditingController(text: '0'),
    'XL': TextEditingController(text: '0'),
    'XXL': TextEditingController(text: '0'),
  };
  bool _shouldShowSizeVariants = false;
  
  // Helper getter to check if current category is clothing
  bool get isClothing {
    if (selectedCategoryId == null || categories.isEmpty) return false;
    final selectedCategory = categories.firstWhere(
      (cat) => cat['id'] == selectedCategoryId,
      orElse: () => <String, dynamic>{},
    );
    return selectedCategory.isNotEmpty && 
           selectedCategory['name']?.toString().toLowerCase().contains('clothing') == true;
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadListings();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    // Dispose size quantity controllers
    for (var controller in _sizeQtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final listings = await AdminService.getAllListings();
      setState(() {
        _listings = listings;
        _filteredListings = listings;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading listings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredListings = _listings.where((listing) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (listing.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Status filter
        bool matchesStatus = _selectedStatusFilter == 'all' ||
            listing.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

        // Category filter
        bool matchesCategory = _selectedCategoryFilter == 'all' ||
            (listing.category?.name?.toLowerCase() == _selectedCategoryFilter.toLowerCase());

        return matchesSearch && matchesStatus && matchesCategory;
      }).toList();
    });
  }

  List<DropdownMenuItem<String>> _buildCategoryFilterItems() {
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'all', child: Text('All Categories')),
    ];

    // Get unique categories from listings
    Set<String> uniqueCategories = {};
    for (var listing in _listings) {
      if (listing.category?.name != null) {
        uniqueCategories.add(listing.category!.name!);
      }
    }

    // Add category items
    for (String categoryName in uniqueCategories) {
      items.add(
        DropdownMenuItem(
          value: categoryName.toLowerCase(),
          child: Text(categoryName),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Manage Listings'),
            Tab(text: 'Add Listing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageListingsTab(),
          _buildAddListingTab(),
        ],
      ),
    );
  }

  Widget _buildManageListingsTab() {
    return RefreshIndicator(
      onRefresh: _loadListings,
      child: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryFilter,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _buildCategoryFilterItems(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredListings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory, size: 84, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
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
                          childAspectRatio: 1.7,
                        ),
                        itemCount: _filteredListings.length,
                        itemBuilder: (context, index) {
                          final listing = _filteredListings[index];
                          return _buildProductCard(listing);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Listing listing) {
    return Card(
      elevation: 3,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: listing.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            Uri.encodeFull(
                              '${AppConfig.fileUrl(listing.imagePath)}?t=${listing.updatedAt.millisecondsSinceEpoch}',
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                ),
                const SizedBox(width: 8),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                        listing.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                        '₱${listing.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                          
                          // Department and Category
                          if (listing.department != null)
                            Text(
                              'Department: ${listing.department!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (listing.category != null)
                            Text(
                              'Category: ${listing.category!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Actions
                      Row(
                        children: [
                          // Delete Button
                          InkWell(
                            onTap: () => _showDeleteConfirmation(listing),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // Edit Button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SuperAdminEditListingScreen(
                                    listing: listing,
                                    userSession: widget.userSession,
                                    onListingUpdated: () => _loadListings(),
                                  ),
                                ),
                              ).then((_) => _loadListings());
                            },
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Status badge in upper right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(listing.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                listing.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
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

  void _showDeleteConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${listing.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteListing(listing.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteListing(int listingId) async {
    try {
      await AdminService.deleteListing(listingId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadListings(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load categories and departments
  Future<void> _loadCategories() async {
    try {
      final cats = await AdminService.getAllCategories();
      final depts = await AdminService.getAllDepartments();
      setState(() {
        categories = cats;
        departments = depts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Image selection methods
  Future<void> _pickImage(ImageSource source, [StateSetter? innerSetState]) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        if (innerSetState != null) {
          innerSetState(() {
            selectedImages.add(File(pickedFile.path));
          });
        } else {
          setState(() {
            selectedImages.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _pickMultipleImages([StateSetter? innerSetState]) async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        if (innerSetState != null) {
          innerSetState(() {
            for (var file in pickedFiles) {
              selectedImages.add(File(file.path));
            }
          });
        } else {
          setState(() {
            for (var file in pickedFiles) {
              selectedImages.add(File(file.path));
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Submit form method
  Future<void> _submitForm([StateSetter? innerSetState]) async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product title is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Prepare image paths
      final List<String> imagePaths = selectedImages.map((file) => file.path).toList();
      
      // Check if using size variants
      if (isClothing && _shouldShowSizeVariants) {
        // Validate that at least one size has stock > 0
        final validVariants = <Map<String, dynamic>>[];
        
        for (var entry in _sizeQtyControllers.entries) {
          final size = entry.key;
          final qty = int.tryParse(entry.value.text.trim()) ?? 0;
          if (qty >= 0) {
            validVariants.add({
              'size': size,
              'stock_quantity': qty,
            });
          }
        }

        if (validVariants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter valid stock quantities for sizes'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Create size variants list
        final sizeVariants = validVariants;

        // Create listing with size variants
        await AdminService.createListingWithVariants(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          price: double.tryParse(priceController.text.trim()) ?? 0,
          status: selectedStatus,
          categoryId: selectedCategoryId!,
          departmentId: selectedDepartmentId,
          imagePaths: imagePaths,
          sizeVariants: sizeVariants,
        );
      } else {
        // Regular single listing creation
        await AdminService.createListing(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          price: double.tryParse(priceController.text.trim()) ?? 0,
          stockQuantity: int.tryParse(stockController.text.trim()) ?? 0,
          status: selectedStatus,
          categoryId: selectedCategoryId!,
          departmentId: selectedDepartmentId,
          imagePaths: imagePaths,
        );
      }
      
      // Clear form
      _clearForm(innerSetState);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload listings
      _loadListings();
      
      // Switch to manage tab
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Clear form method
   void _clearForm([StateSetter? innerSetState]) {
     titleController.clear();
     descriptionController.clear();
     priceController.clear();
     stockController.clear();
     
     // Reset size quantity controllers to '0'
      for (var controller in _sizeQtyControllers.values) {
        controller.text = '0';
      }
     
     if (innerSetState != null) {
       innerSetState(() {
         selectedImages = [];
         selectedCategoryId = null;
         selectedDepartmentId = null;
         selectedStatus = 'pending';
         _shouldShowSizeVariants = false;
       });
     } else {
       setState(() {
         selectedImages = [];
         selectedCategoryId = null;
         selectedDepartmentId = null;
         selectedStatus = 'pending';
         _shouldShowSizeVariants = false;
       });
     }
   }


  
  Widget _buildAddListingTab() {
    // Rebuild the UI when this method is called
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setInnerState) {
        return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Product',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Product Images
          const Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 32, color: Colors.grey),
                        const SizedBox(height: 6),
                        const Text('No images selected', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickMultipleImages(setInnerState),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Multiple', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 28),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera, setInnerState),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Camera', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: const Size(0, 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == selectedImages.length) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () => _pickMultipleImages(setInnerState),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  SizedBox(height: 4),
                                  Text('Add More'),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                setInnerState(() {
                                  selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          
          // Product Details Form
          TextField(
            controller: titleController,
                  onChanged: (value) {
                    setInnerState(() {});
                  },
            decoration: const InputDecoration(
              labelText: 'Product Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
                  onChanged: (value) {
                    setInnerState(() {});
                  },
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  onChanged: (value) {
                    setInnerState(() {});
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Show stock field only for non-clothing items or when size variants are not shown
              if (!isClothing || !_shouldShowSizeVariants)
                Expanded(
                  child: TextField(
                    controller: stockController,
                    onChanged: (value) {
                      setInnerState(() {});
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Category and Department Dropdowns
          Column(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: selectedCategoryId,
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setInnerState(() {
                    selectedCategoryId = value;
                    // Update size variants visibility based on category
                    _shouldShowSizeVariants = isClothing;
                    if (!_shouldShowSizeVariants) {
                      for (var controller in _sizeQtyControllers.values) {
                        controller.text = '0';
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                value: selectedDepartmentId,
                isExpanded: true,
                items: departments.map((department) {
                  return DropdownMenuItem<int>(
                    value: department['id'],
                    child: Text(
                      department['name'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setInnerState(() {
                    selectedDepartmentId = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Size Variants Section (only for clothing)
          if (isClothing && _shouldShowSizeVariants) ...[
            const Text(
              'Size Variants',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter stock quantity for each size:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _sizeQtyControllers.length,
                    itemBuilder: (context, index) {
                      final size = _sizeQtyControllers.keys.elementAt(index);
                      final controller = _sizeQtyControllers[size]!;
                      final stockQty = int.tryParse(controller.text.trim()) ?? 0;
                      final isAvailable = stockQty > 0;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAvailable
                                    ? Colors.green[300]!
                                    : Colors.orange[300]!,
                              ),
                            ),
                            child: Text(
                              size,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isAvailable
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isAvailable
                                        ? Colors.green[300]!
                                        : Colors.orange[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isAvailable
                                        ? Colors.green[300]!
                                        : Colors.orange[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isAvailable
                                        ? Colors.green[600]!
                                        : Colors.orange[600]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                                fillColor: isAvailable
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                filled: true,
                              ),
                              onChanged: (value) {
                                setInnerState(() {});
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Status Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'approved', child: Text('Approved')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            onChanged: (value) {
              setInnerState(() {
                selectedStatus = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitForm(setInnerState),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Product'),
            ),
          ),
        ],
      ),
    );
      });
  }
}