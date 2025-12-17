import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/listing.dart';
// Import Category, Department, User, and SizeVariant from listing.dart
import '../services/admin_service.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;
  final Map<String, dynamic> userSession;
  final List<Category>? categories;
  final VoidCallback? onListingUpdated;

  const EditListingScreen({
    Key? key,
    required this.listing,
    required this.userSession,
    this.categories,
    this.onListingUpdated,
  }) : super(key: key);

  @override
  _EditListingScreenState createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  List<File> _selectedImages = [];
  List<int> _imagesToRemove = [];
  String _selectedStatus = 'pending';
  int? _selectedCategoryId;
  
  List<Category> _categories = [];
  bool _isLoading = false;
  
  // Size variant controllers for clothing
  final Map<String, TextEditingController> _sizeQtyControllers = {
    'XS': TextEditingController(),
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };
  
  bool _shouldShowSizeVariants = false;
  
  bool get _isClothingCategory {
    if (_selectedCategoryId != null && _categories.isNotEmpty) {
      try {
        final selectedCategory = _categories.firstWhere(
          (cat) => cat.id == _selectedCategoryId,
        );
        return selectedCategory.name.toLowerCase().contains('clothing');
      } catch (e) {
        // Category not found, fall back to original listing category
        return widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;
      }
    }
    return widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.listing.title;
    _descriptionController.text = widget.listing.description ?? '';
    _priceController.text = widget.listing.price.toString();
    _stockController.text = widget.listing.stockQuantity.toString();
    _selectedStatus = widget.listing.status ?? 'pending';
    _selectedCategoryId = widget.listing.categoryId;
    
    // Use passed categories if available, otherwise load them
    if (widget.categories != null) {
      _categories = widget.categories!;
    } else {
      _loadCategories();
    }
    
    // Set initial size variants visibility
    _shouldShowSizeVariants = widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;
    
    _initializeSizeVariants();
    _loadCategories();
  }
  
  void _initializeSizeVariants() {
    if (widget.listing.sizeVariants != null && widget.listing.sizeVariants!.isNotEmpty) {
      // Initialize with existing size variants
      for (final variant in widget.listing.sizeVariants!) {
        if (_sizeQtyControllers.containsKey(variant.size)) {
          _sizeQtyControllers[variant.size]!.text = variant.stockQuantity.toString();
        }
      }
    } else if (_isClothingCategory) {
      // Distribute total stock across sizes for clothing items
      final totalStock = widget.listing.stockQuantity;
      final stockPerSize = (totalStock / _sizeQtyControllers.length).floor();
      final remainder = totalStock % _sizeQtyControllers.length;
      
      int index = 0;
      for (final controller in _sizeQtyControllers.values) {
        final stock = stockPerSize + (index < remainder ? 1 : 0);
        controller.text = stock.toString();
        index++;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    
    // Dispose size controllers
    for (final controller in _sizeQtyControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesData = await AdminService.getAllCategories();
       final categories = categoriesData.map((c) => Category.fromJson(c)).toList();
       setState(() {
         _categories = categories;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Card
                _buildSectionCard(
                  title: 'Basic Information',
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Enter product description',
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            prefix: '₱',
                            isNumber: true,
                            enabled: !_isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Stock field - only show if not clothing or size variants are hidden
                    if (!_isClothingCategory || !_shouldShowSizeVariants)
                      Column(
                        children: [
                          _buildTextField(
                            controller: _stockController,
                            label: 'Stock Quantity',
                            isNumber: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    
                    // Category Selection
                    DropdownButtonFormField<int>(
                      decoration: _getInputDecoration('Category'),
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black, fontSize: 14),
                      value: _selectedCategoryId,
                      items: _categories
                          .map((cat) => DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(fontFamily: 'Montserrat'),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          final previousCategoryId = _selectedCategoryId;
                          _selectedCategoryId = value;
                          
                          // Check if category type changed (clothing <-> non-clothing)
                          if (previousCategoryId != null && value != null) {
                            final previousCategory = _categories.firstWhere(
                              (cat) => cat.id == previousCategoryId,
                              orElse: () => Category(id: 0, name: ''),
                            );
                            final newCategory = _categories.firstWhere(
                              (cat) => cat.id == value,
                              orElse: () => Category(id: 0, name: ''),
                            );
                            
                            final wasClothing = previousCategory.name.toLowerCase().contains('clothing');
                            final isNowClothing = newCategory.name.toLowerCase().contains('clothing');
                            
                            // Handle category type change
                            if (wasClothing != isNowClothing) {
                              _clearSizeVariants();
                              if (isNowClothing) {
                                // If changing to clothing, distribute current stock across sizes
                                _distributeSingleStockToSizes();
                                _shouldShowSizeVariants = true;
                              } else {
                                // If changing from clothing to non-clothing, sum up all size stocks
                                _consolidateSizeStocksToSingle();
                                _shouldShowSizeVariants = false;
                              }
                            }
                          }
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Size Variants Section (for clothing)
                if (_isClothingCategory && _shouldShowSizeVariants) ...[
                  _buildSectionCard(
                    title: 'Size & Stock Management',
                    children: [
                      const Text(
                        'Stock per Size:',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600, 
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSizeVariantsGrid(),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Current Images Section
                if (widget.listing.images != null && widget.listing.images!.isNotEmpty) ...[
                   _buildSectionCard(
                     title: 'Current Images',
                     children: [
                       _buildCurrentImagesSection(),
                     ],
                   ),
                   const SizedBox(height: 24),
                ],
                
                // Add New Images Section
                _buildSectionCard(
                  title: 'Add New Images',
                  children: [
                    _buildAddImagesSection(),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _updateListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Update Listing',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Updating listing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, {String? hint, String? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
      labelStyle: const TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
      hintStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    bool isNumber = false,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: _getInputDecoration(label, hint: hint, prefix: prefix),
    );
  }
  
  Widget _buildSizeVariantsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1, // More square-ish for better look
      ),
      itemCount: _sizeQtyControllers.length,
      itemBuilder: (context, index) {
        final entry = _sizeQtyControllers.entries.elementAt(index);
        final size = entry.key;
        final controller = entry.value;
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                size,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCurrentImagesSection() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.listing.images!.length,
        itemBuilder: (context, index) {
          final image = widget.listing.images![index];
          final isMarkedForRemoval = _imagesToRemove.contains(image.id);
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: isMarkedForRemoval ? Colors.red.shade100 : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      AppConfig.fileUrl(image.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isMarkedForRemoval) {
                          _imagesToRemove.remove(image.id);
                        } else {
                          _imagesToRemove.add(image.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isMarkedForRemoval ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMarkedForRemoval ? Icons.undo : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAddImagesSection() {
    return Column(
      children: [
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
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
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }
  
  void _clearSizeVariants() {
    for (final controller in _sizeQtyControllers.values) {
      controller.text = '0';
    }
  }
  
  void _distributeSingleStockToSizes() {
    final totalStock = int.tryParse(_stockController.text) ?? 0;
    final stockPerSize = (totalStock / _sizeQtyControllers.length).floor();
    final remainder = totalStock % _sizeQtyControllers.length;
    
    int index = 0;
    for (final controller in _sizeQtyControllers.values) {
      final stock = stockPerSize + (index < remainder ? 1 : 0);
      controller.text = stock.toString();
      index++;
    }
  }
  
  void _consolidateSizeStocksToSingle() {
    int totalStock = 0;
    for (final controller in _sizeQtyControllers.values) {
      totalStock += int.tryParse(controller.text) ?? 0;
    }
    _stockController.text = totalStock.toString();
    _clearSizeVariants();
  }
  
  Future<void> _updateListing() async {
    if (_titleController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a product title'),
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
    
    // Description is now optional - no validation required
    
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a valid price'),
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
    
    // Validate stock for non-clothing items
    if (!_isClothingCategory || !_shouldShowSizeVariants) {
      final stock = int.tryParse(_stockController.text.trim());
      if (stock == null || stock < 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter a valid stock quantity'),
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
    }
    
    if (_selectedCategoryId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please select a category'),
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
    
    // Size variants are optional for clothing items
    // No validation required - users can save without quantities
    
    setState(() => _isLoading = true);
    
    try {
      // Update basic listing info
      final success = await AdminService.updateListing(
        widget.listing.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stockQuantity: _isClothingCategory && _shouldShowSizeVariants ? null : int.tryParse(_stockController.text.trim()),
        status: _selectedStatus,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        imagesToRemove: _imagesToRemove.isNotEmpty ? _imagesToRemove : null,
        categoryId: _selectedCategoryId,
      );
      
      if (success) {
        // Update size variants if it's clothing
        if (_isClothingCategory && _shouldShowSizeVariants) {
          final sizeVariants = <Map<String, dynamic>>[];
          for (final entry in _sizeQtyControllers.entries) {
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
              widget.listing.id,
              sizeVariants,
            );
          }
        }
        
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Listing updated successfully!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          
          // Call the callback if provided
          if (widget.onListingUpdated != null) {
            widget.onListingUpdated!();
          }
          
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to update listing. Please try again.'),
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
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update listing. Please try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('Network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMessage = 'Session expired. Please log in again.';
        } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
          errorMessage = 'You do not have permission to perform this action.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Listing not found. It may have been deleted.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}