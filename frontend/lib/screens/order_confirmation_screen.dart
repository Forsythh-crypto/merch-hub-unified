import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/listing.dart';
import '../services/order_service.dart';
import '../services/guest_service.dart';
import '../services/auth_services.dart';
import '../config/app_config.dart';
import 'reservation_fee_payment_screen.dart';
import '../widgets/login_prompt_dialog.dart';
import 'user_orders_screen.dart';
import '../services/admin_service.dart';
import '../services/guest_service.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';


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
  final _notesController = TextEditingController();


  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'School of Information Technology Education',
      'logo': 'assets/logos/site.png',
      'color': const Color(0xFF6B7280), // Gray
    },
    {
      'name': 'School of Business and Accountancy',
      'logo': 'assets/logos/sba.png',
      'color': const Color(0xFFF59E0B), // Yellow
    },
    {
      'name': 'School of Criminology',
      'logo': 'assets/logos/soc.png',
      'color': const Color(0xFF800000), // Maroon
    },
    {
      'name': 'School of Engineering',
      'logo': 'assets/logos/soe.png',
      'color': const Color(0xFFEA580C), // Orange
    },
    {
      'name': 'School of Teacher Education',
      'logo': 'assets/logos/ste.png',
      'color': const Color(0xFF2563EB), // Blue
    },
    {
      'name': 'School of Humanities',
      'logo': 'assets/logos/soh.png',
      'color': const Color(0xFF7C3AED), // Purple
    },
    {
      'name': 'School of Health Sciences',
      'logo': 'assets/logos/sohs.png',
      'color': const Color(0xFF059669), // Green
    },
    {
      'name': 'School of International Hospitality Management',
      'logo': 'assets/logos/sihm.png',
      'color': const Color(0xFFDC2626), // Red
    },
    {
      'name': 'Official UDD Merch',
      'logo': 'assets/logos/udd_merch.png',
      'color': const Color(0xFF1F2937), // Dark Gray
    },
  ];

  String _getDepartmentLogo() {
    print('Listing Department Info: ${widget.listing.department?.name}'); // Debug print
    
    if (widget.listing.department == null) {
      // Fallback logic if department object is null but departmentId is present
      // This might be tricky without a direct mapping of ID to Name here, 
      // but let's default to UDD logo if name is missing.
      return 'assets/logos/uddess.png';
    }

    final departmentName = widget.listing.department!.name;
    
    final department = _departments.firstWhere(
      (dept) => dept['name'] == departmentName,
      orElse: () => {'logo': 'assets/logos/uddess.png'},
    );
    
    return department['logo'];
  }

  bool _isSubmitting = false;
  List<Listing> _relatedListings = [];



  Future<void> _loadRelatedListings() async {
    try {
      final isGuest = await GuestService.isGuestMode();
      final listings = isGuest 
          ? await AdminService.getPublicListings()
          : await AdminService.getApprovedListings();
      
      if (mounted) {
        setState(() {
          _relatedListings = listings
              .where((l) => l.id != widget.listing.id)
              .take(5)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading related listings: $e');
    }
  }
  bool _isGuestMode = false;
  String? _selectedSize;
  final Map<String, int> _sizeQuantities = {};
  double _totalAmount = 0.0;

  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeSizeData();
    _checkGuestStatus();
    _getUserEmail();
    _loadRelatedListings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh guest status when returning from login
    _checkGuestStatus();
    _getUserEmail();
  }

  Future<void> _checkGuestStatus() async {
    final isGuest = await GuestService.isGuestMode();
    if (mounted) {
      setState(() {
        _isGuestMode = isGuest;
      });
      if (!isGuest) {
        await _getUserEmail();
      }
    }
  }

  Future<void> _getUserEmail() async {
    if (!_isGuestMode) {
      final userData = await AuthService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _userEmail = userData['email'];
        });
      }
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



  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if user is guest and prompt login
    if (_isGuestMode) {
      final shouldLogin = await GuestService.promptLogin(
         context,
         'checkout',
         returnRoute: 'pop',
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
    final totalAmount = _totalAmount;
    
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
      items: [
        {
          'listing_id': widget.listing.id,
          'quantity': int.parse(_quantityController.text),
          'size': _selectedSize,
        }
      ],
      email: _userEmail ?? '',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(result['message']),
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addToCart() async {
    // Check if user is guest and prompt login
    if (_isGuestMode) {
      final shouldLogin = await GuestService.promptLogin(
         context,
         'add_to_cart',
         returnRoute: 'pop',
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

    if (_selectedSize == null && widget.listing.sizeVariants != null && widget.listing.sizeVariants!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size')),
        );
      }
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    await Provider.of<CartService>(context, listen: false).addItem(
      widget.listing,
      quantity,
      _selectedSize,
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
       Navigator.pop(context); // Close modal
       
       showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: const Text('Item added to cart successfully!', style: TextStyle(fontFamily: 'Montserrat')),
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
    _quantityController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},');
  }


  String _getImageUrl() {
    if (widget.listing.imagePath == null || widget.listing.imagePath!.isEmpty) {
      return '';
    }
    return AppConfig.fileUrl(
      '${widget.listing.imagePath}?t=${widget.listing.updatedAt.millisecondsSinceEpoch}',
    );
  }

  void _showOrderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header: Image, Price, Stock
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Container(
                         width: 100,
                         height: 100,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(8),
                           color: Colors.grey[100],
                           image: DecorationImage(
                             image: NetworkImage(_getImageUrl()),
                             fit: BoxFit.cover,
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               '₱${_formatPrice(widget.listing.price)}',
                               style: const TextStyle(
                                 fontSize: 20,
                                 fontWeight: FontWeight.bold,
                                 color: Color(0xFF1E3A8A),
                                 fontFamily: 'Montserrat',
                               ),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               'Stock: ${_getCurrentStock()}',
                               style: TextStyle(
                                 color: Colors.grey[600],
                                 fontFamily: 'Montserrat',
                               ),
                             ),
                           ],
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close),
                         onPressed: () => Navigator.pop(context),
                       ),
                     ],
                   ),
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 16),
                     child: Divider(),
                   ),
                   
                   Expanded(
                     child: SingleChildScrollView(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Size Selection
                           if (widget.listing.sizeVariants != null && widget.listing.sizeVariants!.isNotEmpty) ...[
                             const Text(
                               'Size',
                               style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 12),
                             Wrap(
                               spacing: 12,
                               runSpacing: 12,
                               children: widget.listing.sizeVariants!.map((variant) {
                                  final isSelected = _selectedSize == variant.size;
                                  final isAvailable = variant.stockQuantity > 0;
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _selectedSize = variant.size;
                                      });
                                      // Update parent state as well to sync
                                      setState(() {
                                        _selectedSize = variant.size;
                                        _calculateTotal(); // Update total calculation
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            variant.size,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                          if (variant.stockQuantity <= 0)
                                            Text(
                                              '(pre-order)',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white70 : Colors.red[300],
                                                fontSize: 10,
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                               }).toList(),
                             ),
                             const SizedBox(height: 24),
                           ],

                           // Quantity
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text(
                                 'Quantity',
                                 style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                               ),
                               Row(
                                 children: [
                                   IconButton(
                                     icon: const Icon(Icons.remove),
                                     onPressed: () {
                                       int current = int.tryParse(_quantityController.text) ?? 1;
                                       if (current > 1) {
                                         setModalState(() {
                                           _quantityController.text = (current - 1).toString();
                                         });
                                         setState(() => _calculateTotal());
                                       }
                                     },
                                   ),
                                   Container(
                                     width: 50,
                                     alignment: Alignment.center,
                                     child: Text(
                                        _quantityController.text,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                     ),
                                   ),
                                   IconButton(
                                     icon: const Icon(Icons.add),
                                     onPressed: () {
                                       int current = int.tryParse(_quantityController.text) ?? 1;
                                       setModalState(() {
                                         _quantityController.text = (current + 1).toString();
                                       });
                                       setState(() => _calculateTotal());
                                     },
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),

                   // Footer Action
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: Row(
                       children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _addToCart(); 
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1E3A8A)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF1E3A8A)
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                _submitOrder(); // Proceed to order
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Reserve Now',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                              ),
                            ),
                          ),
                       ],
                     ),
                   ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reviews (${widget.listing.reviewCount})',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: widget.listing.reviews?.length ?? 0,
                  itemBuilder: (context, index) {
                    final review = widget.listing.reviews![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) => Icon(
                                  index < review.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.review ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Always pop back to previous screen to maintain proper navigation stack
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          toolbarHeight: 100, // Increased height for bigger logo
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 28,
                  color: Colors.black,
                ),
                tooltip: 'My Cart',
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // Increased padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Information Card
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Images - Full Width (First Child)
                      Container(
                        height: 350,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                           color: Colors.white, // Match container
                           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Stack(
                          children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: widget.listing.images != null &&
                                        widget.listing.images!.isNotEmpty
                                    ? PageView.builder(
                                        itemCount: widget.listing.images!.length,
                                        itemBuilder: (context, index) {
                                          final image = widget.listing.images![index];
                                          return Image.network(
                                            Uri.encodeFull(AppConfig.fileUrl(image.imagePath)),
                                            width: double.infinity,
                                            height: 350,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Center(child: Icon(Icons.error_outline, size: 40, color: Colors.grey)),
                                          );
                                        },
                                      )
                                    : widget.listing.imagePath != null &&
                                            widget.listing.imagePath!.isNotEmpty
                                        ? Image.network(
                                            _getImageUrl(),
                                            width: double.infinity,
                                            height: 350,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 60,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'No image available',
                                                  style: TextStyle(color: Colors.grey[400]),
                                                ),
                                              ],
                                            ),
                                          ),
                              ),
                              // Department Logo Overlay
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    _getDepartmentLogo(),
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Product Details (Padded)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

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
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Price and Stock Status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  Text(
                                    '₱${_formatPrice(widget.listing.price)}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E3A8A),
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                // Rating Summary
                                if (widget.listing.reviewCount > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.listing.averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${widget.listing.reviewCount})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCurrentStock() > 0
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _getCurrentStock() > 0
                                        ? Colors.green[200]!
                                        : Colors.orange[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCurrentStock() > 0
                                          ? Icons.check_circle_outline
                                          : Icons.access_time,
                                      size: 16,
                                      color: _getCurrentStock() > 0
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getCurrentStock() > 0
                                          ? 'In Stock (${_getCurrentStock()})'
                                          : 'Pre-order',
                                      style: TextStyle(
                                        color: _getCurrentStock() > 0
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Order Details Card
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                        const SizedBox(height: 20),

                        // Size and Quantity selection moved to bottom sheet


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
                              '₱${_formatPrice(_totalAmount)}',
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
                    onPressed: _isSubmitting ? null : () => _showOrderOptions(context),
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
                
                if (widget.listing.reviews != null && widget.listing.reviews!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.listing.reviews!.take(3).map((review) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) => Icon(
                                index < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.review ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (widget.listing.reviews!.length > 3)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showAllReviews,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'See All Reviews',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
                
                if (_relatedListings.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'You might also like',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _relatedListings.length,
                      itemBuilder: (context, index) {
                        final listing = _relatedListings[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderConfirmationScreen(
                                  listing: listing,
                                  sourceScreen: 'suggested',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: listing.imagePath != null
                                        ? Image.network(
                                            Uri.encodeFull('${AppConfig.baseUrl}/api/files/${listing.imagePath}'),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          fontFamily: 'Montserrat',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${_formatPrice(listing.price)}',
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}