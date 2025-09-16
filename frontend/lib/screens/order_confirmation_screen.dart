import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/listing.dart';
import '../services/order_service.dart';
import '../services/guest_service.dart';
import '../config/app_config.dart';
import 'reservation_fee_payment_screen.dart';
import '../widgets/login_prompt_dialog.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Listing listing;
  final String? sourceScreen; // Track where user came from

  const OrderConfirmationScreen({
    super.key, 
    required this.listing,
    this.sourceScreen,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountCodeController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGuestMode = false;
  String? _selectedSize;
  final Map<String, int> _sizeQuantities = {};
  double _totalAmount = 0.0;
  String? _appliedDiscountCode;
  double _discountAmount = 0.0;
  bool _isValidatingDiscount = false;
  double _discountPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSizeData();
    _checkGuestStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh guest status when returning from login
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    final isGuest = await GuestService.isGuestMode();
    if (mounted) {
      setState(() {
        _isGuestMode = isGuest;
      });
    }
  }

  void _initializeSizeData() {
    if (widget.listing.sizeVariants != null &&
        widget.listing.sizeVariants!.isNotEmpty) {
      // Use size variants from the listing
      for (var variant in widget.listing.sizeVariants!) {
        _sizeQuantities[variant.size] = variant.stockQuantity;
      }
      // Set default selected size to the first available size
      _selectedSize = widget.listing.sizeVariants!.first.size;
    }
    _calculateTotal();
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final baseAmount = widget.listing.price * quantity;
    setState(() {
      _totalAmount = baseAmount;
    });
  }

  int _getCurrentStock() {
    if (_selectedSize != null && widget.listing.sizeVariants != null) {
      final variant = widget.listing.sizeVariants!
          .firstWhere((v) => v.size == _selectedSize);
      return variant.stockQuantity;
    }
    return widget.listing.stockQuantity;
  }

  Future<void> _validateDiscountCode() async {
    final code = _discountCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isValidatingDiscount = true);

    try {
      // Mock discount validation for now
       await Future.delayed(const Duration(seconds: 1));
       
       // Simple mock validation
       final Map<String, dynamic> result;
       if (code == 'STUDENT10') {
         result = {
           'success': true,
           'discount': {'discount_percentage': 10.0}
         };
       } else if (code == 'WELCOME20') {
         result = {
           'success': true,
           'discount': {'discount_percentage': 20.0}
         };
       } else {
         result = {
           'success': false,
           'message': 'Invalid discount code'
         };
       }
      if (result['success']) {
        final discountData = result['discount'];
        _discountPercentage = discountData['discount_percentage'];
        final discountAmount = (_totalAmount * _discountPercentage / 100);

        setState(() {
          _appliedDiscountCode = code;
          _discountAmount = discountAmount;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Discount applied: ${_discountPercentage.toStringAsFixed(0)}% off'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _appliedDiscountCode = null;
          _discountAmount = 0.0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invalid discount code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _appliedDiscountCode = null;
        _discountAmount = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating discount code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isValidatingDiscount = false);
    }
  }

  void _removeDiscount() {
    setState(() {
      _appliedDiscountCode = null;
      _discountAmount = 0.0;
      _discountPercentage = 0.0;
      _discountCodeController.clear();
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user is guest and prompt login
    if (_isGuestMode) {
      final shouldLogin = await GuestService.promptLogin(
         context,
         'checkout',
         returnRoute: '/order-confirmation',
         returnArguments: {'listing': widget.listing},
       );
      if (shouldLogin) {
        // Refresh guest status after potential login
        await _checkGuestStatus();
        // If still guest after login prompt, don't proceed
        if (_isGuestMode) return;
      } else {
        return; // User chose not to login
      }
    }

    // Show confirmation dialog
    final confirmed = await _showOrderConfirmationDialog();
    if (!confirmed) return;

    await _processOrder();
  }

  Future<bool> _showOrderConfirmationDialog() async {
    final isPreOrder = _getCurrentStock() <= 0;
    final orderType = isPreOrder ? 'Pre-order' : 'Reservation';
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final totalAmount = _totalAmount - _discountAmount;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm $orderType',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to ${isPreOrder ? 'pre-order' : 'reserve'} this item?',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Item: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.listing.title,
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Quantity: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                      ],
                    ),
                    if (_selectedSize != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Size: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          Text(
                            _selectedSize!,
                            style: const TextStyle(fontFamily: 'Montserrat'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Total: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Text(
                          '₱${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPreOrder) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a pre-order. You will need to pay a reservation fee to secure your order.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPreOrder ? const Color(0xFFFF6B35) : const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirm ${isPreOrder ? 'Pre-order' : 'Reservation'}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _processOrder() async {
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
        discountCode: _appliedDiscountCode,
        discountAmount: _discountAmount,
      );

      if (result['success']) {
        if (mounted) {
          // Navigate to payment screen for reservation fee
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationFeePaymentScreen(
                order: result['order'],
                totalAmount: _totalAmount - _discountAmount,
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

  @override
  void dispose() {
    _quantityController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _discountCodeController.dispose();
    super.dispose();
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate back based on source screen
          if (widget.sourceScreen == 'user_listings') {
            // If came from user listings, just pop back to preserve navigation stack
            Navigator.pop(context);
          } else {
            // Default: Navigate back to home screen while preserving authentication state
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.listing.stockQuantity > 0 ? 'Reserve Item' : 'Pre-order Item',
            style: const TextStyle(
              fontFamily: 'Montserrat',
            ),
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
                  elevation: 0,
                  color: Colors.transparent,
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
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Product Images
                        Container(
                          height: 300,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: widget.listing.images != null &&
                                    widget.listing.images!.isNotEmpty
                                ? PageView.builder(
                                    itemCount: widget.listing.images!.length,
                                    itemBuilder: (context, index) {
                                      final image = widget.listing.images![index];
                                      return Image.network(
                                        Uri.encodeFull(AppConfig.fileUrl(image.imagePath)),
                                        width: double.infinity,
                                        height: 300,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                Text(
                                                  'Image not available',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ],
                                            ),
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
                                        height: 300,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                                Text(
                                                  'Image not available',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                            Text(
                                              'No image available',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Product Title
                        Text(
                          widget.listing.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Product Description
                        if (widget.listing.description != null &&
                             widget.listing.description!.isNotEmpty) ...[
                          Text(
                            widget.listing.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Price and Stock Status
                        Row(
                          children: [
                            Text(
                              '₱${widget.listing.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getCurrentStock() > 0
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getCurrentStock() > 0
                                      ? Colors.green[300]!
                                      : Colors.orange[300]!,
                                ),
                              ),
                              child: Text(
                                _getCurrentStock() > 0
                                    ? 'In Stock (${_getCurrentStock()})'
                                    : 'Pre-order Available',
                                style: TextStyle(
                                  color: _getCurrentStock() > 0
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Order Details Card
                Card(
                  elevation: 0,
                  color: Colors.transparent,
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
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Size Selection (if available)
                        if (widget.listing.sizeVariants != null &&
                             widget.listing.sizeVariants!.isNotEmpty ||
                             _sizeQuantities.isNotEmpty) ...[
                          Text(
                            'Select Size:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
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
                                              ? const Color(0xFF1E3A8A)
                                              : isAvailable
                                                  ? Colors.white
                                                  : Colors.orange[50],
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF1E3A8A)
                                                : isAvailable
                                                    ? Colors.grey[300]!
                                                    : Colors.orange[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${variant.size} ${!isAvailable ? '(Pre-order)' : '(${variant.stockQuantity})'}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : isAvailable
                                                ? Colors.black
                                                : Colors.orange[700],
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontFamily: 'Montserrat',
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
                                              ? const Color(0xFF1E3A8A)
                                              : isAvailable
                                                  ? Colors.white
                                                  : Colors.orange[50],
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF1E3A8A)
                                                : isAvailable
                                                    ? Colors.grey[300]!
                                                    : Colors.orange[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$size ${!isAvailable ? '(Pre-order)' : '($quantity)'}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : isAvailable
                                                ? Colors.black
                                                : Colors.orange[700],
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontFamily: 'Montserrat',
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
                            labelText: 'Quantity *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_cart),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            // Check stock for selected size
                            if (_selectedSize != null && widget.listing.sizeVariants != null) {
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
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Discount Code Section
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _discountCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Discount Code (Optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.local_offer),
                                  hintText: 'Enter discount code',
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isValidatingDiscount ? null : _validateDiscountCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: _isValidatingDiscount
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Apply',
                                      style: TextStyle(fontFamily: 'Montserrat'),
                                    ),
                            ),
                          ],
                        ),

                        // Applied Discount Display
                        if (_appliedDiscountCode != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Discount "$_appliedDiscountCode" applied: -₱${_discountAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeDiscount,
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Notes Input
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Special Instructions (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                            hintText: 'Any special requests or notes...',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Order Summary Card
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              '₱${_totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount ($_appliedDiscountCode):',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[600],
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              Text(
                                '-₱${_discountAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[600],
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(thickness: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              '₱${(_totalAmount - _discountAmount).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCurrentStock() > 0
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                ),
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
                              fontFamily: 'Montserrat',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
