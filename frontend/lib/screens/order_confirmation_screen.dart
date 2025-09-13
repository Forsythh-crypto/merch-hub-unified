import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';
import 'reservation_fee_payment_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Listing listing;

  const OrderConfirmationScreen({super.key, required this.listing});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  // For size selection
  String? _selectedSize;
  final Map<String, int> _sizeQuantities = {};

  @override
  void initState() {
    super.initState();
    _initializeSizeData();
  }

  void _initializeSizeData() {
    if (widget.listing.sizeVariants != null &&
        widget.listing.sizeVariants!.isNotEmpty) {
      for (final variant in widget.listing.sizeVariants!) {
        _sizeQuantities[variant.size] = variant.stockQuantity;
      }
      // Set first size as default (allow pre-orders for sizes with no stock)
      final firstVariant = widget.listing.sizeVariants!.first;
      _selectedSize = firstVariant.size;
    } else {
      // Check if it's a clothing item without size variants
      final isClothing = widget.listing.category?.name.toLowerCase().contains('clothing') ?? false;
      if (isClothing) {
        // Create virtual size variants by distributing total stock
        final totalStock = widget.listing.stockQuantity;
        final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
        final stockPerSize = totalStock > 0 ? (totalStock / sizes.length).floor() : 0;
        final remainder = totalStock > 0 ? totalStock % sizes.length : 0;
        
        for (int i = 0; i < sizes.length; i++) {
          final stock = stockPerSize + (i < remainder ? 1 : 0);
          _sizeQuantities[sizes[i]] = stock;
        }
        
        // Set first size as default
        _selectedSize = sizes.first;
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await OrderService.createOrder(
        listingId: widget.listing.id,
        quantity: int.parse(_quantityController.text),
        email: _emailController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        size: _selectedSize, // Add size parameter
      );

      if (result['success']) {
        if (mounted) {
          // Navigate to payment screen for reservation fee
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationFeePaymentScreen(
                order: result['order'],
                totalAmount: _totalAmount,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  double get _totalAmount {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return widget.listing.price * quantity;
  }

  // Helper method to get current stock for selected size
  int _getCurrentStock() {
    if (widget.listing.sizeVariants != null &&
        widget.listing.sizeVariants!.isNotEmpty &&
        _selectedSize != null) {
      try {
        final variant = widget.listing.sizeVariants!
            .firstWhere((v) => v.size == _selectedSize);
        return variant.stockQuantity;
      } catch (e) {
        return 0;
      }
    }
    return widget.listing.stockQuantity;
  }

  String _getImageUrl() {
    if (widget.listing.imagePath == null || widget.listing.imagePath!.isEmpty) {
      return '';
    }
    return AppConfig.fileUrl(
      '${widget.listing.imagePath}?t=${widget.listing.updatedAt.millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listing.stockQuantity > 0 ? 'Reserve Item' : 'Pre-order Item',
        ),
        backgroundColor: widget.listing.stockQuantity > 0
            ? const Color(0xFF1E3A8A)
            : const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Information Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Images
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.listing.images != null &&
                                  widget.listing.images!.isNotEmpty
                              ? PageView.builder(
                                  itemCount: widget.listing.images!.length,
                                  itemBuilder: (context, index) {
                                    final image = widget.listing.images![index];
                                    return Image.network(
                                      Uri.encodeFull(AppConfig.fileUrl(image.imagePath)),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 50),
                                        );
                                      },
                                    );
                                  },
                                )
                              : widget.listing.imagePath != null &&
                                      widget.listing.imagePath!.isNotEmpty
                                  ? Image.network(
                                      _getImageUrl(),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 50),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50),
                                    ),
                        ),
                      ),

                      // Image indicators for multiple images
                      if (widget.listing.images != null &&
                          widget.listing.images!.length > 1)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.listing.images!.length,
                              (index) => Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Product Details
                      Text(
                        widget.listing.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Order Type Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCurrentStock() > 0
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.1)
                              : const Color(0xFFFF6B35).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getCurrentStock() > 0
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFFF6B35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCurrentStock() > 0
                                  ? Icons.inventory
                                  : Icons.schedule,
                              size: 16,
                              color: _getCurrentStock() > 0
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFFFF6B35),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getCurrentStock() > 0
                                  ? 'In Stock - Reserve Now'
                                  : 'Pre-order Available',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getCurrentStock() > 0
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFFF6B35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.listing.description != null &&
                          widget.listing.description!.isNotEmpty)
                        Text(
                          widget.listing.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: ₱${widget.listing.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if ((widget.listing.sizeVariants != null &&
                          widget.listing.sizeVariants!.isNotEmpty) ||
                          _sizeQuantities.isNotEmpty) ...[
                        Text(
                          'Available Sizes:',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: widget.listing.sizeVariants != null &&
                                  widget.listing.sizeVariants!.isNotEmpty
                              ? widget.listing.sizeVariants!.map((variant) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: variant.stockQuantity > 0
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${variant.size}: ${variant.stockQuantity}',
                                      style: TextStyle(
                                        color: variant.stockQuantity > 0
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList()
                              : _sizeQuantities.entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entry.value > 0
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${entry.key}: ${entry.value}',
                                      style: TextStyle(
                                        color: entry.value > 0
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),
                      ] else ...[
                        Text(
                          'Available Stock: ${widget.listing.stockQuantity}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: widget.listing.stockQuantity > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Order Details Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Size Selection (for clothing items)
                      if ((widget.listing.sizeVariants != null &&
                          widget.listing.sizeVariants!.isNotEmpty) ||
                          _sizeQuantities.isNotEmpty) ...[
                        Text(
                          'Select Size:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.listing.sizeVariants != null &&
                                  widget.listing.sizeVariants!.isNotEmpty
                              ? widget.listing.sizeVariants!.map((variant) {
                                  final isSelected = _selectedSize == variant.size;
                                  final isAvailable = variant.stockQuantity > 0;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSize = variant.size;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isAvailable
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFFFF6B35))
                                            : isAvailable
                                            ? Colors.grey[200]
                                            : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? (isAvailable
                                                    ? const Color(0xFF1E3A8A)
                                                    : const Color(0xFFFF6B35))
                                              : isAvailable
                                              ? Colors.grey[300]!
                                              : Colors.orange[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        '${variant.size} (${variant.stockQuantity})',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : isAvailable
                                              ? Colors.black
                                              : Colors.orange[700],
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList()
                              : _sizeQuantities.entries.map((entry) {
                                  final size = entry.key;
                                  final quantity = entry.value;
                                  final isSelected = _selectedSize == size;
                                  final isAvailable = quantity > 0;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSize = size;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isAvailable
                                                  ? const Color(0xFF1E3A8A)
                                                  : const Color(0xFFFF6B35))
                                            : isAvailable
                                            ? Colors.grey[200]
                                            : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? (isAvailable
                                                    ? const Color(0xFF1E3A8A)
                                                    : const Color(0xFFFF6B35))
                                              : isAvailable
                                              ? Colors.grey[300]!
                                              : Colors.orange[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        '$size ($quantity)',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : isAvailable
                                              ? Colors.black
                                              : Colors.orange[700],
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quantity Input
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_cart),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Please enter a valid quantity';
                          }

                          // Check stock based on size selection (allow pre-orders)
                          if (widget.listing.sizeVariants != null &&
                              widget.listing.sizeVariants!.isNotEmpty) {
                            if (_selectedSize == null) {
                              return 'Please select a size';
                            }
                            final selectedVariant = widget.listing.sizeVariants!
                                .firstWhere(
                                  (v) => v.size == _selectedSize,
                                  orElse: () =>
                                      throw Exception('Size not found'),
                                );
                            // Allow pre-orders even when stock is 0
                            if (selectedVariant.stockQuantity > 0 &&
                                quantity > selectedVariant.stockQuantity) {
                              return 'Quantity exceeds available stock for selected size';
                            }
                          } else {
                            // Allow pre-orders even when stock is 0
                            if (widget.listing.stockQuantity > 0 &&
                                quantity > widget.listing.stockQuantity) {
                              return 'Quantity exceeds available stock';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update total
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          hintText: 'Enter your email for order confirmation',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Notes Input
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                          hintText: 'Any special requests or notes...',
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 16),

                      // Total Amount
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E3A8A)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₱${_totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Information Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Row(
                        children: [
                          Icon(Icons.payment, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 8),
                          Text(
                            'Payment Method: Cash on Pickup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Please bring the exact amount in cash',
                        style: TextStyle(fontSize: 14),
                      ),
                      const Text(
                        '• Valid ID required for pickup',
                        style: TextStyle(fontSize: 14),
                      ),
                      const Text(
                        '• Pickup location: Department Office',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Order confirmation will be sent to your email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCurrentStock() > 0
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getCurrentStock() > 0
                                  ? 'Creating Reservation...'
                                  : 'Creating Pre-order...',
                            ),
                          ],
                        )
                      : Text(
                          _getCurrentStock() > 0
                              ? 'Reserve Now'
                              : 'Pre-order Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
