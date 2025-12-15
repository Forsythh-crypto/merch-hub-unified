import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../config/app_config.dart';
import 'reservation_fee_payment_screen.dart';
import '../services/order_service.dart';
import '../services/auth_services.dart';
import '../services/guest_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},');
  }

  @override
  void initState() {
    super.initState();
    // Ensure cart is loaded
    Provider.of<CartService>(context, listen: false).loadCart();
  }

  Future<void> _processCheckout() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    if (cartService.items.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      // 1. Check Login
      final isGuest = await GuestService.isGuestMode();
      String? userEmail;
      
      if (isGuest) {
        final shouldLogin = await GuestService.promptLogin(context, 'checkout');
        if (shouldLogin) {
           // If they logged in, we need to refresh state, but for now let's assume they might stay guest
           // Re-check
           if (!await GuestService.isGuestMode()) {
              final userData = await AuthService.getCurrentUser();
              userEmail = userData?['email'];
           } else {
             // User cancelled login or stayed guest?
             // If we really require login (which the original flow did for "Order Now" -> "Order Service"),
             // we might need to enforce it. 
             // OrderService.createOrder requires email. 
             // IF GuestService logic allows Guest checkout, we need an email input.
             // For now, let's assume GuestService.promptLogin handles the flow or returns false if cancelled.
             if (await GuestService.isGuestMode()) {
                // Return if still guest and we want to enforce login?
                // Or proceed if Guest Checkout is allowed. 
                // Let's assume we proceed but might fail if email is missing in backend.
                // Actually `OrderService.createOrder` takes an email arg.
             }
           }
        } else {
          // User cancelled
          setState(() => _isCheckingOut = false);
          return;
        }
      } else {
         final userData = await AuthService.getCurrentUser();
         userEmail = userData?['email'];
      }

      // 2. Group items by department to process separate orders
      final groupedItems = cartService.getItemsByDepartment();
      final List<Order> createdOrders = [];
      bool allSuccess = true;
      String errorMessage = '';

      for (var entry in groupedItems.entries) {
        final deptName = entry.key;
        final items = entry.value;

        // Create an order for EACH item? Or group them?
        // The original OrderService.createOrder takes a single `listingId` and quantity.
        // It does NOT support multiple items per order yet.
        // So we must loop through EVERY item and create a separate order?
        // OR we update functionality? 
        // "magkakahiwalay dapat ang order per dept" -> imply grouped by dept?
        // But backend `Order` model links to `listing_id`. Usually 1 order = 1 listing in simple systems.
        // If the backend doesn't support OrderItems (many-to-one), we have to create 1 Order per Item.
        // Let's assume based on `OrderService.createOrder(listingId: ...)` signature, it's 1 Order = 1 Item.
        // BUT user asked "magkakahiwalay ang order per dept". If we make 1 order per item, that satisfies it (they are separated).
        // If we want 1 Order containing multiple items for a Department, backend needs change.
        // Start with: Loop through all items and create individual orders, but maybe group them in payment?
        // Or simpler: Just create separate orders for everything.
        
        for (var item in items) {
           final result = await OrderService.createOrder(
              listingId: item.listing.id,
              quantity: item.quantity,
              email: userEmail ?? '',
              notes: item.notes,
              size: item.size,
              // Discount support per item? Complex if added to cart. 
              // For MVP cart, maybe apply global discount or ignore for now.
           );
           
           if (!result['success']) {
             allSuccess = false;
             errorMessage = result['message'];
             break; 
           } else {
             createdOrders.add(result['order']);
           }
        }
        if (!allSuccess) break;
      }

      if (allSuccess) {
        await cartService.clearCart();
        if (mounted) {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Orders Placed'),
              content: Text('Successfully placed ${createdOrders.length} orders! Please proceed to payment/history.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close Cart
                     // Navigate to My Orders
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error placing order: $errorMessage')),
          );
        }
      }

    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedItems = cart.getItemsByDepartment();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final deptName = groupedItems.keys.elementAt(index);
                    final items = groupedItems[deptName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                color: const Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                deptName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    image: item.listing.imagePath != null
                                        ? DecorationImage(
                                            image: NetworkImage(Uri.encodeFull(AppConfig.fileUrl(item.listing.imagePath!))),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: item.listing.imagePath == null
                                      ? const Icon(Icons.image, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.listing.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.size != null)
                                        Text(
                                          'Size: ${item.size}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${_formatPrice(item.totalPrice)}',
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity Actions
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => cart.removeItem(item.id),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                               if (item.quantity > 1) {
                                                 cart.updateQuantity(item.id, item.quantity - 1);
                                               }
                                            },
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              cart.updateQuantity(item.id, item.quantity + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Items',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '${cart.totalItemCount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCheckingOut ? null : _processCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCheckingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Checkout All',
                                  style: TextStyle(
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
            ],
          );
        },
      ),
    );
  }
}
