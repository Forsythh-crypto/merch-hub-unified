import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/user_role.dart';
import '../services/order_service.dart';
import '../config/app_config.dart';

class AdminOrdersScreen extends StatefulWidget {
  final UserSession userSession;
  final bool showAppBar;
  final int? initialOrderId;

  const AdminOrdersScreen({
    Key? key, 
    required this.userSession, 
    this.showAppBar = true,
    this.initialOrderId,
  }) : super(key: key);

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

      // If there's an initial order ID, switch to the correct tab
      if (widget.initialOrderId != null) {
        final initialOrder = orders.firstWhere(
          (o) => o.id == widget.initialOrderId, 
          orElse: () => orders.first
        );
        
        if (initialOrder.id == widget.initialOrderId) {
          final statusIndex = _statusTabs.indexOf(initialOrder.status);
          if (statusIndex != -1) {
            _tabController.animateTo(statusIndex);
          }
        }
      }
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
      labelColor: const Color(0xFF1E3A8A), // Enhanced color
      unselectedLabelColor: Colors.grey[600],
      indicatorColor: const Color(0xFF1E3A8A),
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      tabs: _tabLabels.map((label) => Tab(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label),
        ),
      )).toList(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Redesigned body content
    final bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                color: Colors.grey[50], // Light background
                child: TabBarView(
                  controller: _tabController,
                  children: _statusTabs.map((status) => _buildOrdersList(status)).toList(),
                ),
              );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 120,
              centerTitle: true,
              title: Image.asset(
                'assets/logos/uddess.png',
                height: 100,
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                    onPressed: _loadOrders,
                    tooltip: 'Refresh Orders',
                  ),
                ),
              ],
              bottom: _buildTabBar(),
            )
          : null,
      body: widget.showAppBar
          ? bodyContent
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: const Text(
                    'Orders Management',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  width: double.infinity,
                  child: _buildTabBar(),
                ),
                Expanded(child: bodyContent),
              ],
            ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored Status Strip
              Container(
                width: 6,
                color: statusColor,
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order ID and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt_long, size: 20, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${order.orderNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(order.createdAt),
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              _getStatusDisplay(order.status).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
                      
                      // Product Details
                      if (order.items.isNotEmpty) ...[
                        // Multi-item display
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.listing?.title ?? 'Product Unavailable',
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        if (item.size != null)
                                          _buildDetailBadge(Icons.straighten, 'Size: ${item.size}'),
                                        _buildDetailBadge(Icons.layers, 'Qty: ${item.quantity}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ] else ...[
                        // Legacy Single Item Fallback
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.listing?.title ?? 'Product Unavailable',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      if (order.size != null)
                                        _buildDetailBadge(Icons.straighten, 'Size: ${order.size}'),
                                      _buildDetailBadge(Icons.layers, 'Qty: ${order.quantity}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Price (Total for single item order)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Department & Customer Info
                      if (order.department != null)
                        Row(
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.department!.name,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      
                      if (order.user != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                             Icon(Icons.person, size: 14, color: Colors.grey[400]),
                             const SizedBox(width: 4),
                             Text(
                               order.user?.name ?? 'Guest',
                               style: TextStyle(
                                 fontFamily: 'Montserrat',
                                 fontSize: 12,
                                 color: Colors.grey[600],
                               ),
                             ),
                          ],
                        ),
                      ],


                      // Customer Info
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], // Very light background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                order.user?.name.isNotEmpty == true ? order.user!.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.user?.name ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                  Text(
                                    order.user?.email ?? 'No email',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Reservation Fee Section
                      if (order.status == 'pending') ...[
                        const SizedBox(height: 16),
                        _buildReservationFeeSection(order),
                      ],

                      // Special Notes or Pickup Date
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.yellow[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow[200]!),
                          ),
                          child: Text(
                            'Note: ${order.notes}',
                            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                          ),
                        ),
                      ],
                      if (order.status == 'ready_for_pickup' && order.pickupDate != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Pickup: ${_formatDate(order.pickupDate!)}',
                                style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updatingStatusOrderIds.contains(order.id) 
                              ? null 
                              : () => _showStatusUpdateDialog(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), // Dark Blue
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _updatingStatusOrderIds.contains(order.id)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Status',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationFeeSection(Order order) {
    final isPaid = order.reservationFeePaid;
    final color = isPaid ? Colors.green : Colors.orange;
    final bgColor = isPaid ? Colors.green[50]! : Colors.orange[50]!;
    final borderColor = isPaid ? Colors.green[200]! : Colors.orange[200]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: color[700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reservation Fee (35%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color[800],
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '₱${order.calculatedReservationFeeAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color[800],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          
          if (!isPaid && order.paymentReceiptPath != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmingReservationOrderIds.contains(order.id)
                        ? null
                        : () => _confirmReservationFee(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[700],
                      elevation: 0,
                      side: BorderSide(color: Colors.green[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _confirmingReservationOrderIds.contains(order.id)
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showReceiptImage(context, order.paymentReceiptPath!),
                  icon: const Icon(Icons.receipt),
                  color: Colors.blue[700],
                  tooltip: 'View Receipt',
                ),
              ],
            ),
          ] else if (isPaid) ...[
             const SizedBox(height: 8),
             Text(
               'Payment Verified',
               style: TextStyle(color: Colors.green[700], fontSize: 12, fontStyle: FontStyle.italic),
             ),
          ],
        ],
      ),
    );
  }
}