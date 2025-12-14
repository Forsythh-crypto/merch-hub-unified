import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/guest_service.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';
import 'receipt_upload_screen.dart';
import 'reservation_fee_payment_screen.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({Key? key}) : super(key: key);

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  final List<String> _statusTabs = [
    'pending',
    'confirmed', 
    'ready_for_pickup',
    'completed',
    'cancelled'
  ];

  final List<String> _tabLabels = [
    'To Prepare',
    'Confirmed',
    'Ready',
    'Completed', 
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final orders = await OrderService.getUserOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ready_for_pickup':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'To be prepared';
      case 'confirmed':
        return 'Confirmed';
      case 'ready_for_pickup':
        return 'Ready for pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  List<Order> _getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  Widget _buildOrdersList(String status) {
    final filteredOrders = _getOrdersByStatus(status);
    
    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_getStatusDisplay(status).toLowerCase()} orders',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontFamily: 'Montserrat'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.listing?.title ?? 'Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.orderNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusDisplay(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display quantity with size if available
                      Text(
                        order.size != null 
                            ? 'Quantity: ${order.quantity} (Size: ${order.size})'
                            : order.listing?.size != null
                                ? 'Quantity: ${order.quantity} (Size: ${order.listing!.size})'
                                : 'Quantity: ${order.quantity}',
                        style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
                      ),
                      if (order.email != null && order.email!.isNotEmpty)
                        Text(
                          'Email: ${order.email}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      order.department?.name ?? 'Department',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Montserrat'),
                    ),
                  ],
                ),
              ],
            ),

            // Reservation Fee Information
            if (order.status == 'pending') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.reservationFeePaid 
                      ? Colors.green[50] 
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: order.reservationFeePaid 
                        ? Colors.green[200]! 
                        : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          order.reservationFeePaid 
                              ? Icons.check_circle 
                              : Icons.payment,
                          color: order.reservationFeePaid 
                              ? Colors.green[700] 
                              : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reservation Fee (35%): ₱${order.calculatedReservationFeeAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: order.reservationFeePaid 
                                ? Colors.green[700] 
                                : Colors.orange[700],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.reservationFeePaid 
                          ? 'Payment received - Order confirmed'
                          : 'Payment pending - Upload receipt to confirm order',
                      style: TextStyle(
                        fontSize: 12,
                        color: order.reservationFeePaid 
                            ? Colors.green[600] 
                            : Colors.orange[600],
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Notes: ${order.notes}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Montserrat'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Ordered on ${_formatDate(order.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Montserrat'),
            ),
            if (order.status == 'ready_for_pickup' &&
                order.pickupDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Pickup by: ${_formatDate(order.pickupDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],

            // Action Buttons
            if (order.status == 'pending' && !order.reservationFeePaid && order.paymentReceiptPath == null) ...[              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationFeePaymentScreen(
                              order: order,
                              totalAmount: order.totalAmount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('View QR Code', style: TextStyle(fontFamily: 'Montserrat')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptUploadScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Receipt', style: TextStyle(fontFamily: 'Montserrat')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelOrderDialog(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order', style: TextStyle(fontFamily: 'Montserrat')),
                ),
              ),
            ],
            
            // Rating Section for Completed Orders
            if (order.status == 'completed') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate this order:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (order.rating != null) ...[
                       // Show existing rating
                       Row(
                         children: [
                           ...List.generate(5, (index) => Icon(
                             index < order.rating! ? Icons.star : Icons.star_border,
                             color: Colors.amber,
                             size: 20,
                           )),
                           const SizedBox(width: 8),
                           Text(
                             '${order.rating}/5',
                             style: const TextStyle(
                               fontWeight: FontWeight.w500,
                               fontSize: 14,
                               fontFamily: 'Montserrat',
                             ),
                           ),
                         ],
                       ),
                       if (order.review != null && order.review!.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Text(
                           'Your review: ${order.review}',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.grey[600],
                             fontStyle: FontStyle.italic,
                             fontFamily: 'Montserrat',
                           ),
                         ),
                       ],
                     ] else ...[
                      // Show rating input
                      Row(
                        children: List.generate(5, (index) => GestureDetector(
                          onTap: () => _rateOrder(order, index + 1),
                          child: Icon(
                            Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          ),
                        )),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap stars to rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // View Receipt Button (when receipt is already uploaded)
            if (order.status == 'pending' && !order.reservationFeePaid && order.paymentReceiptPath != null) ...[              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationFeePaymentScreen(
                              order: order,
                              totalAmount: order.totalAmount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('View QR Code', style: TextStyle(fontFamily: 'Montserrat')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showReceiptImage(context, order.paymentReceiptPath!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.image),
                      label: const Text('View Receipt', style: TextStyle(fontFamily: 'Montserrat')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Function to show cancel order confirmation dialog
  void _showCancelOrderDialog(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order', style: TextStyle(fontFamily: 'Montserrat')),
          content: Text(
            'Are you sure you want to cancel order #${order.orderNumber}?\n\nThis action cannot be undone.',
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Order', style: TextStyle(fontFamily: 'Montserrat')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelOrder(order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order', style: TextStyle(fontFamily: 'Montserrat')),
            ),
          ],
        );
      },
    );
  }

  // Function to cancel an order
  Future<void> _cancelOrder(Order order) async {
    try {
      await OrderService.cancelOrder(order.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Order cancelled successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Reload orders to reflect the change
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to cancel order: ${e.toString()}'),
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
  }

  // Function to rate an order
  void _rateOrder(Order order, int rating) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String reviewText = '';
        return AlertDialog(
          title: Text('Rate Order #${order.orderNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Write a review (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience...',
                ),
                maxLines: 3,
                onChanged: (value) => reviewText = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitRating(order, rating, reviewText);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Rating'),
            ),
          ],
        );
      },
    );
  }

  // Function to submit rating
  Future<void> _submitRating(Order order, int rating, String review) async {
    try {
      await OrderService.rateOrder(order.id, rating, review);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Rating submitted successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        // Reload orders to reflect the change
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to submit rating: ${e.toString()}'),
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
  }

  // Function to show receipt image in a dialog
  void _showReceiptImage(BuildContext context, String receiptPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Payment Receipt'),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                centerTitle: true,
                elevation: 0,
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        AppConfig.fileUrl(receiptPath),
                        fit: BoxFit.contain,
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
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading receipt image',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Transform.scale(
          scale: 1.5,
          child: Image.asset(
            'assets/logos/uddess.png',
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _statusTabs.map((status) => _buildOrdersList(status)).toList(),
            ),
    );
  }
}
