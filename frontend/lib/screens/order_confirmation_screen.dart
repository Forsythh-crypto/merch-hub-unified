import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';

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
  Map<String, int> _sizeQuantities = {};

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
      // Set first available size as default
      final firstVariant = widget.listing.sizeVariants!.first;
      if (firstVariant.stockQuantity > 0) {
        _selectedSize = firstVariant.size;
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
          // Show order success dialog with order number
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text('Order Successful!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your order has been placed successfully!'),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Number:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            result['order']?.orderNumber ?? 'N/A',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'A confirmation email has been sent to ${_emailController.text.trim()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pop(context, true); // Navigate back to listings
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
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

  String _getImageUrl() {
    if (widget.listing.imagePath == null || widget.listing.imagePath!.isEmpty) {
      return '';
    }
    return 'http://192.168.100.11:8000/api/files/${widget.listing.imagePath}?t=${widget.listing.updatedAt.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-order'),
        backgroundColor: const Color(0xFF1E3A8A),
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

                      // Product Image
                      if (widget.listing.imagePath != null &&
                          widget.listing.imagePath!.isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _getImageUrl(),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
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
                      if (widget.listing.sizeVariants != null &&
                          widget.listing.sizeVariants!.isNotEmpty) ...[
                        Text(
                          'Available Sizes:',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: widget.listing.sizeVariants!.map((variant) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: variant.stockQuantity > 0
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${variant.size}: ${variant.stockQuantity}',
                                style: TextStyle(
                                  color: variant.stockQuantity > 0
                                      ? Colors.green[800]
                                      : Colors.red[800],
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
                      if (widget.listing.sizeVariants != null &&
                          widget.listing.sizeVariants!.isNotEmpty) ...[
                        Text(
                          'Select Size:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.listing.sizeVariants!.map((variant) {
                            final isSelected = _selectedSize == variant.size;
                            final isAvailable = variant.stockQuantity > 0;

                            return GestureDetector(
                              onTap: isAvailable
                                  ? () {
                                      setState(() {
                                        _selectedSize = variant.size;
                                      });
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : isAvailable
                                      ? Colors.grey[200]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1E3A8A)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  '${variant.size} (${variant.stockQuantity})',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isAvailable
                                        ? Colors.black
                                        : Colors.grey[500],
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

                          // Check stock based on size selection
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
                            if (quantity > selectedVariant.stockQuantity) {
                              return 'Quantity exceeds available stock for selected size';
                            }
                          } else {
                            if (quantity > widget.listing.stockQuantity) {
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
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Order...'),
                          ],
                        )
                      : const Text(
                          'Pre-order',
                          style: TextStyle(
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
