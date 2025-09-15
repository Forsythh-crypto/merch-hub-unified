import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../services/guest_service.dart';

class LoginPromptDialog extends StatelessWidget {
  final String action;
  final String message;
  final String? returnRoute;
  final Map<String, dynamic>? returnArguments;
  
  const LoginPromptDialog({
    super.key,
    required this.action,
    this.message = 'You need to login to perform this action.',
    this.returnRoute,
    this.returnArguments,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.blue[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Login Required',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please login or create an account to continue.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop('register');
          },
          child: const Text(
            'Register',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop('login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Static method to show the dialog
  static Future<bool> show(BuildContext context, {
    required String action,
    String? customMessage,
    String? returnRoute,
    Map<String, dynamic>? returnArguments,
  }) async {
    String message;
    switch (action) {
      case 'reserve_product':
        message = 'You need to login to reserve this product.';
        break;
      case 'pre_order':
        message = 'You need to login to pre-order this product.';
        break;
      case 'add_to_cart':
        message = 'You need to login to add items to your cart.';
        break;
      case 'checkout':
        message = 'You need to login to proceed with checkout.';
        break;
      case 'view_orders':
        message = 'You need to login to view your orders.';
        break;
      case 'create_listing':
        message = 'You need to login to create a listing.';
        break;
      default:
        message = customMessage ?? 'You need to login to perform this action.';
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginPromptDialog(
        action: action,
        message: message,
        returnRoute: returnRoute,
        returnArguments: returnArguments,
      ),
    );

    if (result == 'login') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            returnRoute: returnRoute,
            returnArguments: returnArguments,
          ),
        ),
      );
      // Check if user is no longer in guest mode after login
      final isStillGuest = await GuestService.isGuestMode();
      return !isStillGuest;
    } else if (result == 'register') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            returnRoute: returnRoute,
            returnArguments: returnArguments,
          ),
        ),
      );
      // Check if user is no longer in guest mode after registration
      final isStillGuest = await GuestService.isGuestMode();
      return !isStillGuest;
    }

    return false;
  }
}