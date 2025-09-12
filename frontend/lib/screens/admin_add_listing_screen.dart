import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';

class AdminAddListingScreen extends StatefulWidget {
  const AdminAddListingScreen({super.key});

  @override
  State<AdminAddListingScreen> createState() => _AdminAddListingScreenState();
}

class _AdminAddListingScreenState extends State<AdminAddListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  
  // Size variant controllers for clothing
  final Map<String, TextEditingController> _sizeQtyControllers = {
    'XS': TextEditingController(text: '0'),
    'S': TextEditingController(text: '0'),
    'M': TextEditingController(text: '0'),
    'L': TextEditingController(text: '0'),
    'XL': TextEditingController(text: '0'),
    'XXL': TextEditingController(text: '0'),
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final controller in _sizeQtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await AdminService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isClothingCategory() {
    if (_selectedCategoryId != null && _categories.isNotEmpty) {
      try {
        final selectedCategory = _categories.firstWhere(
          (cat) => cat['id'] == _selectedCategoryId,
        );
        return selectedCategory['name'].toLowerCase().contains('clothing');
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  Future<void> _createListing() async {
    // Basic validation
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Stock validation based on category (optional - allows preorders)
    int totalStock = 0;
    List<Map<String, dynamic>>? sizeVariants;
    
    if (_isClothingCategory()) {
      // Process size variants (optional stock)
      sizeVariants = [];
      for (final entry in _sizeQtyControllers.entries) {
        final qty = int.tryParse(entry.value.text.trim()) ?? 0;
        // Allow 0 stock for preorders
        sizeVariants.add({
          'size': entry.key,
          'stock_quantity': qty,
        });
        totalStock += qty;
      }
    } else {
      // Regular stock validation (optional)
      final stockText = _stockController.text.trim();
      if (stockText.isNotEmpty) {
        final stock = int.tryParse(stockText);
        if (stock == null || stock < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid stock quantity'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        totalStock = stock;
      } else {
        // Allow empty stock for preorders
        totalStock = 0;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's department - regular admins can only add to their own department
      final userDepartment = 1; // Default department for now
      
      List<String>? imagePaths;
      if (_selectedImages.isNotEmpty) {
        imagePaths = _selectedImages.map((file) => file.path).toList();
      }

      bool success;
      if (_isClothingCategory() && sizeVariants != null && sizeVariants.isNotEmpty) {
        // Use createListingWithVariants for clothing items
        success = await AdminService.createListingWithVariants(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          categoryId: _selectedCategoryId!,
          departmentId: userDepartment,
          imagePaths: imagePaths,
          status: 'pending',
          sizeVariants: sizeVariants,
        );
      } else {
        // Use regular createListing for non-clothing items
        success = await AdminService.createListing(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          stockQuantity: totalStock,
          categoryId: _selectedCategoryId!,
          departmentId: userDepartment,
          imagePaths: imagePaths,
          status: 'pending',
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create listing'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Listing'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Product Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '₱',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Size & Stock Management Section
                  if (_isClothingCategory()) ...[
                    const Text(
                      'Size & Stock Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            'Stock per Size (Optional - Leave 0 for preorders):',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
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
                              final entry = _sizeQtyControllers.entries.elementAt(index);
                              final size = entry.key;
                              final controller = entry.value;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      size,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity (Optional - Leave empty for preorders)',
                        hintText: 'Enter stock quantity or leave empty for preorders',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image),
                    label: Text('Select Images (${_selectedImages.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Selected Images:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E3192),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Create Listing',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}