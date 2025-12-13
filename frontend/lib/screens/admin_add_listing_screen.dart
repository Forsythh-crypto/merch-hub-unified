import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';

class AdminAddListingScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onListingCreated;
  final Map<String, dynamic>? userSession;
  
  const AdminAddListingScreen({super.key, this.showAppBar = true, this.onListingCreated, this.userSession});

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
      final userDepartment = widget.userSession?['departmentId'] ?? 1; // Use user's department or default to 1
      
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
          
          // Clear form fields
          _titleController.clear();
          _descriptionController.clear();
          _priceController.clear();
          _stockController.clear();
          setState(() {
            _selectedCategoryId = null;
            _selectedImages.clear();
            _sizeQtyControllers.forEach((key, controller) => controller.text = '0');
          });
          
          // Notify parent if callback is provided
          if (widget.onListingCreated != null) {
            widget.onListingCreated!();
          } else {
            Navigator.pop(context, true); // Return true to indicate success
          }
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
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: widget.showAppBar ? AppBar(
        title: const Text(
          'Add New Listing',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E3A8A), // Consistent Admin Blue
        foregroundColor: Colors.white,
        elevation: 0,
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Information'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Product Title',
                          hint: 'e.g., University Hoodie',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Enter product details...',
                          maxLines: 4,
                          isOptional: true,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                          style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black87),
                          decoration: _inputDecoration('Category'),
                          items: _categories.map((category) {
                            return DropdownMenuItem<int>(
                              value: category['id'],
                              child: Text(
                                category['name'],
                                style: const TextStyle(fontFamily: 'Montserrat'),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Pricing & Inventory'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _priceController,
                          label: 'Price',
                          hint: '0.00',
                          prefixText: '₱ ',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 20),
                        
                        if (_isClothingCategory()) ...[
                         const Align(
                           alignment: Alignment.centerLeft,
                           child: Text(
                             'Size Variants & Stock',
                             style: TextStyle(
                               fontFamily: 'Montserrat',
                               fontWeight: FontWeight.w600,
                               fontSize: 16,
                               color: Color(0xFF1E3A8A),
                             ),
                           ),
                         ),
                         const SizedBox(height: 8),
                         const Align(
                           alignment: Alignment.centerLeft,
                            child: Text(
                              'Enter stock for each size (0 for pre-order)',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: _sizeQtyControllers.length,
                            itemBuilder: (context, index) {
                              final entry = _sizeQtyControllers.entries.elementAt(index);
                              return _buildSizeStockInput(entry.key, entry.value);
                            },
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _stockController,
                            label: 'Stock Quantity',
                            hint: 'Leave empty for pre-orders',
                            keyboardType: TextInputType.number,
                            isOptional: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Product Images'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePickerArea(),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Selected Images',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _createListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create Listing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // UI Helpers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
          color: Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Montserrat'),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isOptional = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15),
      decoration: _inputDecoration(
        isOptional ? '$label (Optional)' : label,
        hint: hint,
        prefixText: prefixText,
      ),
    );
  }

  Widget _buildSizeStockInput(String size, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              size,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
              ),
              style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 32,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to upload images',
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}