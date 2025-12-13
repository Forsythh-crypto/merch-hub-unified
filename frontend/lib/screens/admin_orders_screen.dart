import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/user_role.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';

class AdminOrdersScreen extends StatefulWidget {
  final UserSession userSession;
  final bool showAppBar;

  const AdminOrdersScreen({Key? key, required this.userSession, this.showAppBar = true})
    : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  
  // Per-order loading states
  Set<int> _updatingStatusOrderIds = {};
  Set<int> _confirmingReservationOrderIds = {};

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await OrderService.getAdminOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    final filteredOrders = _orders.where((order) => order.status == status).toList();
    
    // Sort by creation date (newest first)
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filteredOrders;
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
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    // Prevent multiple updates for the same order
    if (_updatingStatusOrderIds.contains(order.id)) return;
    
    setState(() {
      _updatingStatusOrderIds.add(order.id);
    });

    try {
      final result = await OrderService.updateOrderStatus(
        orderId: order.id,
        status: newStatus,
      );

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadOrders(); // Reload orders
        
        // Trigger sales report refresh if order is completed
        if (newStatus.toLowerCase() == 'completed') {
          _notifySalesReportRefresh();
        }
      } else {
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error updating order: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _updatingStatusOrderIds.remove(order.id);
      });
    }
  }

  void _notifySalesReportRefresh() {
    // Store a flag in SharedPreferences to indicate sales report needs refresh
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('sales_report_needs_refresh', true);
    });
  }

  Future<void> _confirmReservationFee(Order order) async {
    // Prevent multiple confirmations for the same order
    if (_confirmingReservationOrderIds.contains(order.id)) return;
    
    setState(() {
      _confirmingReservationOrderIds.add(order.id);
    });

    try {
      final result = await OrderService.confirmReservationFee(order.id);

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadOrders(); // Reload orders
      } else {
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error confirming reservation fee: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _confirmingReservationOrderIds.remove(order.id);
      });
    }
  }

  Future<void> _showStatusUpdateDialog(Order order) async {
    final statuses = [
      'pending',
      'confirmed',
      'ready_for_pickup',
      'completed',
      'cancelled',
    ];
    final currentStatus = order.status;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Update Order Status',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 16),
              Text(
                'Current Status: ${_getStatusDisplay(currentStatus)}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 16),
              Text(
                'Select New Status:',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              const SizedBox(height: 8),
              ...statuses
                  .map(
                    (status) => RadioListTile<String>(
                      title: Text(
                        _getStatusDisplay(status),
                        style: const TextStyle(fontFamily: 'Montserrat'),
                      ),
                      value: status,
                      groupValue: currentStatus,
                      onChanged: (value) {
                        Navigator.pop(context);
                        if (value != null && value != currentStatus) {
                          _updateOrderStatus(order, value);
                        }
                      },
                    ),
                  )
                  .toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
          ],
        );
      },
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
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.orderNumber}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (order.user != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${order.user!.name} (${order.user!.email})',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
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
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _updatingStatusOrderIds.contains(order.id) 
                          ? null 
                          : () => _showStatusUpdateDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                      child: _updatingStatusOrderIds.contains(order.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Status',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ],
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
                      Text(
                        'Quantity: ${order.quantity}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                        ),
                      ),
                      if (order.size != null)
                        Text(
                          'Size: ${order.size}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        'Department: ${order.department?.name ?? 'Unknown'}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                        ),
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
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    Text(
                      'Ordered: ${_formatDate(order.createdAt)}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.reservationFeePaid 
                          ? 'Payment received - Order confirmed'
                          : 'Payment pending - Receipt uploaded: ${order.paymentReceiptPath != null ? "Yes" : "No"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: order.reservationFeePaid 
                            ? Colors.green[600] 
                            : Colors.orange[600],
                      ),
                    ),
                    if (!order.reservationFeePaid && order.paymentReceiptPath != null) ...[  
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _confirmingReservationOrderIds.contains(order.id)
                                  ? null
                                  : () => _confirmReservationFee(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00D4AA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _confirmingReservationOrderIds.contains(order.id)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                _confirmingReservationOrderIds.contains(order.id)
                                    ? 'Confirming...'
                                    : 'Confirm Payment',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showReceiptImage(context, order.paymentReceiptPath!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.image),
                            label: const Text('View Receipt'),
                          ),
                        ],
                      ),
                    ],
                    if (order.reservationFeePaid && order.paymentReceiptPath != null) ...[  
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReceiptImage(context, order.paymentReceiptPath!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.image),
                          label: const Text('View Receipt'),
                        ),
                      ),
                    ],
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
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            if (order.status == 'ready_for_pickup' &&
                order.pickupDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pickup by: ${_formatDate(order.pickupDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  // Department logo mapping
  String _getDepartmentLogo(String? departmentName) {
    if (departmentName == null) return 'assets/logos/udd_merch.png'; // Default to UDD Merch or generic
    
    switch (departmentName.toLowerCase()) {
      case 'school of information technology education':
        return 'assets/logos/site.png';
      case 'school of business and accountancy':
        return 'assets/logos/sba.png';
      case 'school of criminology':
        return 'assets/logos/soc.png';
      case 'school of engineering':
        return 'assets/logos/soe.png';
      case 'school of teacher education':
        return 'assets/logos/ste.png';
      case 'school of humanities':
        return 'assets/logos/soh.png';
      case 'school of health sciences':
        return 'assets/logos/sohs.png';
      case 'school of international hospitality management':
        return 'assets/logos/sihm.png';
      case 'official udd merch':
        return 'assets/logos/udd_merch.png';
      default:
        return 'assets/logos/uddess.png'; // Fallback to main logo
    }
  }

  @override
  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      labelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
      ),
      tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = _isLoading
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
              );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFF9FAFB),
              elevation: 0,
              toolbarHeight: 120,
              centerTitle: true,
              title: Transform.scale(
                scale: 1.5,
                child: Image.asset(
                  'assets/logos/uddess.png',
                  height: 100,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOrders,
                ),
              ],
              bottom: _buildTabBar(),
            )
          : null,
      body: widget.showAppBar
          ? bodyContent
          : Column(
              children: [
                Container(
                  color: const Color(0xFFF9FAFB),
                  width: double.infinity,
                  child: _buildTabBar(),
                ),
                Expanded(child: bodyContent),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}