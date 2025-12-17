import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../services/admin_service.dart';
import '../config/app_config.dart';

class SuperAdminEditListingScreen extends StatefulWidget {
  final Listing listing;
  final UserSession userSession;
  final VoidCallback onListingUpdated;

  const SuperAdminEditListingScreen({
    super.key,
    required this.listing,
    required this.userSession,
    required this.onListingUpdated,
  });

  @override
  State<SuperAdminEditListingScreen> createState() => _SuperAdminEditListingScreenState();
}

class _SuperAdminEditListingScreenState extends State<SuperAdminEditListingScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  
  List<File> selectedImages = [];
  List<int> imagesToRemove = [];

  String selectedStatus = 'pending';
  
  // Department and Category data
  List<Department> departments = [];
  List<Category> categories = [];
  int? selectedDepartmentId;
  int? selectedCategoryId;
  bool _isLoadingData = false;
  
  // Size variant controllers for clothing
  final Map<String, TextEditingController> _sizeQtyControllers = {
    'XS': TextEditingController(),
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };
  
  bool _isLoading = false;
  bool _shouldShowSizeVariants = false;
  bool get isClothing {
    if (selectedCategoryId != null && categories.isNotEmpty) {
      final selectedCategory = categories.firstWhere(
        (cat) => cat.id == selectedCategoryId,
        orElse: () => Category(id: 0, name: ''),
      );
      return selectedCategory.name.toLowerCase().contains('clothing');
    }
    return widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;
  }
  bool get hasSizeVariants => widget.listing.sizeVariants != null && widget.listing.sizeVariants!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(text: widget.listing.description);
    _priceController = TextEditingController(text: widget.listing.price.toString());
    _stockController = TextEditingController(text: widget.listing.stockQuantity.toString());
    selectedStatus = widget.listing.status;
    
    // Initialize selected values
    selectedDepartmentId = widget.listing.departmentId;
    selectedCategoryId = widget.listing.categoryId;
    
    // Set initial size variants visibility based on current category
    _shouldShowSizeVariants = widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;

    // Initialize size controllers
    _initializeSizeControllers();
    
    // Load departments and categories
    _loadDepartmentsAndCategories();
  }

  void _initializeSizeControllers() {
    if (hasSizeVariants && widget.listing.sizeVariants != null) {
      // If listing has size variants, use those values
      for (final variant in widget.listing.sizeVariants!) {
        if (_sizeQtyControllers.containsKey(variant.size)) {
          _sizeQtyControllers[variant.size]!.text = variant.stockQuantity.toString();
        }
      }
    } else if (isClothing) {
      // If it's clothing but no size variants, distribute the total stock across sizes
      final totalStock = widget.listing.stockQuantity;
      final defaultStock = totalStock > 0 ? (totalStock / 6).round() : 0;

      for (final controller in _sizeQtyControllers.values) {
        controller.text = defaultStock.toString();
      }

      // Put remaining stock in the first size (M)
      if (totalStock > 0) {
        final remaining = totalStock - (defaultStock * 6);
        if (remaining > 0) {
          _sizeQtyControllers['M']!.text = (defaultStock + remaining).toString();
        }
      }
    }
  }

  Future<void> _loadDepartmentsAndCategories() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load departments and categories from API
      final departmentsData = await AdminService.getAllDepartments();
      final categoriesData = await AdminService.getAllCategories();

      setState(() {
        departments = departmentsData.map((dept) => Department.fromJson(dept)).toList();
        categories = categoriesData.map((cat) => Category.fromJson(cat)).toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: Text('Error loading data: $e', style: const TextStyle(fontFamily: 'Montserrat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/logos/uddess.png',
            height: 100,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Makes back button black
        elevation: 0,
        toolbarHeight: 100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Section
                  _buildSectionHeader('Basic Information'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                    decoration: const InputDecoration(
                      labelText: 'Product Title',
                      labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(fontFamily: 'Montserrat'),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          style: const TextStyle(fontFamily: 'Montserrat'),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                            border: OutlineInputBorder(),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!isClothing || !_shouldShowSizeVariants)
                        Expanded(
                          child: TextField(
                            controller: _stockController,
                            style: const TextStyle(fontFamily: 'Montserrat'),
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity',
                              labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Section
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontFamily: 'Montserrat'))),
                        DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontFamily: 'Montserrat'))),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(fontFamily: 'Montserrat'))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Department Section
                  SizedBox(
                    width: double.infinity,
                    child: _isLoadingData
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading departments...', style: TextStyle(fontFamily: 'Montserrat')),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: selectedDepartmentId,
                            style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
                            isExpanded: true, // Fix for overflow
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: departments
                                .map((dept) => DropdownMenuItem<int>(
                                      value: dept.id,
                                      child: Text(
                                        dept.name,
                                        style: const TextStyle(fontFamily: 'Montserrat'),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDepartmentId = value;
                              });
                            },
                          ),
                  ),
                  
                  // Category Section
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoadingData
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading categories...', style: TextStyle(fontFamily: 'Montserrat')),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            style: const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(fontFamily: 'Montserrat', color: Colors.black54),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: categories
                                .map((cat) => DropdownMenuItem<int>(
                                      value: cat.id,
                                      child: Text(cat.name, style: const TextStyle(fontFamily: 'Montserrat')),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                final previousCategoryId = selectedCategoryId;
                                selectedCategoryId = value;
                                
                                // Check if category type changed (clothing <-> non-clothing)
                                 if (previousCategoryId != null && value != null) {
                                   final previousCategory = categories.firstWhere(
                                     (cat) => cat.id == previousCategoryId,
                                     orElse: () => Category(id: 0, name: ''),
                                   );
                                   final newCategory = categories.firstWhere(
                                     (cat) => cat.id == value,
                                     orElse: () => Category(id: 0, name: ''),
                                   );
                                   
                                   final wasClothing = previousCategory.name.toLowerCase().contains('clothing');
                                   final isNowClothing = newCategory.name.toLowerCase().contains('clothing');
                                   
                                   // Clear size variants if category type changed
                                    if (wasClothing != isNowClothing) {
                                      _clearSizeVariants();
                                      if (isNowClothing) {
                                        // If changing to clothing, distribute current stock across sizes
                                         _distributeSingleStockToSizes();
                                         _shouldShowSizeVariants = true;
                                      } else {
                                        // If changing from clothing to non-clothing, sum up all size stocks
                                        _consolidateSizeStocksToSingle();
                                        // Force UI to hide size variants section
                                        _shouldShowSizeVariants = false;
                                      }
                                    }
                                 }
                              });
                            },
                          ),
                  ),
                  
                  // Size Variants Section (for clothing)
                  if (isClothing && _shouldShowSizeVariants) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('Size & Stock Management'),
                    const SizedBox(height: 16),
                    _buildSizeVariantsSection(),
                  ],
                  
                  // Images Section
                  const SizedBox(height: 32),
                  _buildSectionHeader('Product Images'),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  
                  // Action Buttons
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontFamily: 'Montserrat')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _updateListing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Update Listing', style: TextStyle(fontFamily: 'Montserrat')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  Widget _buildSizeVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock per Size:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Montserrat'),
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
                        fontFamily: 'Montserrat',
                        color: isAvailable
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(fontFamily: 'Montserrat'),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        fillColor: isAvailable
                            ? Colors.green[50]
                            : Colors.orange[50],
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display existing images
          if (widget.listing.images != null && widget.listing.images!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Images:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Montserrat'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.listing.images!.length,
                    itemBuilder: (context, index) {
                      final image = widget.listing.images![index];
                      final isMarkedForRemoval = imagesToRemove.contains(image.id);
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isMarkedForRemoval ? Colors.red : Colors.grey,
                            width: isMarkedForRemoval ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                AppConfig.fileUrl(image.imagePath),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey),
                                        Text('Failed to load', style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isMarkedForRemoval)
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.delete, color: Colors.white, size: 32),
                                ),
                              ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isMarkedForRemoval) {
                                      imagesToRemove.remove(image.id);
                                    } else {
                                      imagesToRemove.add(image.id);
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
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Show placeholder when no images available
          if ((widget.listing.images == null || widget.listing.images!.isEmpty) && selectedImages.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No Images',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Montserrat'),
                  ),
                ],
              ),
            ),
          
          // Display new selected images
          if (selectedImages.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Images:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Montserrat'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImages[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImages.removeAt(index);
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
              ],
            ),
          
          // No images placeholder
          if ((widget.listing.images == null || widget.listing.images!.isEmpty) && selectedImages.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No images', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Image action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage(
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (images.isNotEmpty) {
                        setState(() {
                          selectedImages.addAll(images.map((img) => File(img.path)));
                        });
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                          content: Text('Error picking images: $e', style: const TextStyle(fontFamily: 'Montserrat')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery', style: TextStyle(fontFamily: 'Montserrat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setState(() {
                          selectedImages.add(File(image.path));
                        });
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                          content: Text('Error taking photo: $e', style: const TextStyle(fontFamily: 'Montserrat')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera', style: TextStyle(fontFamily: 'Montserrat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateListing() async {
    if (_titleController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: const Text('Please enter a product title', style: TextStyle(fontFamily: 'Montserrat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update basic listing info
      await AdminService.updateListing(
        widget.listing.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? widget.listing.price,
        stockQuantity: int.tryParse(_stockController.text) ?? widget.listing.stockQuantity,
        status: selectedStatus,
        images: selectedImages,
        imagesToRemove: imagesToRemove,
        categoryId: selectedCategoryId,
        departmentId: selectedDepartmentId,
      );

      // Update size variants if it's clothing
      if (isClothing || hasSizeVariants) {
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

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: const Text('Listing updated successfully', style: TextStyle(fontFamily: 'Montserrat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        ),
      );

      widget.onListingUpdated();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating listing: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: Text('Error updating listing: $e', style: const TextStyle(fontFamily: 'Montserrat')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Clear all size variant controllers
  void _clearSizeVariants() {
    for (final controller in _sizeQtyControllers.values) {
      controller.clear();
    }
  }

  // Distribute single stock quantity across all sizes when changing to clothing
  void _distributeSingleStockToSizes() {
    final totalStock = int.tryParse(_stockController.text) ?? 0;
    if (totalStock > 0) {
      final stockPerSize = (totalStock / _sizeQtyControllers.length).floor();
      final remainder = totalStock % _sizeQtyControllers.length;
      
      int index = 0;
      for (final controller in _sizeQtyControllers.values) {
        final stock = stockPerSize + (index < remainder ? 1 : 0);
        controller.text = stock.toString();
        index++;
      }
    } else {
      for (final controller in _sizeQtyControllers.values) {
        controller.text = '0';
      }
    }
  }

  // Consolidate all size stocks into single stock when changing from clothing
  void _consolidateSizeStocksToSingle() {
    int totalStock = 0;
    for (final controller in _sizeQtyControllers.values) {
      final stock = int.tryParse(controller.text) ?? 0;
      totalStock += stock;
    }
    _stockController.text = totalStock.toString();
    _clearSizeVariants();
  }
}